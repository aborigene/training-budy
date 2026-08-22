import hmac
import logging
import os

import anthropic
import httpx
from fastapi import FastAPI, Request, Response

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("telegram-bot")

app = FastAPI()

TELEGRAM_BOT_TOKEN = os.environ["TELEGRAM_BOT_TOKEN"]
TELEGRAM_WEBHOOK_SECRET = os.environ["TELEGRAM_WEBHOOK_SECRET"]
TELEGRAM_API_URL = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}"

# Comma-separated list of Telegram chat IDs allowed to talk to the bot.
ALLOWED_CHAT_IDS = {
    chat_id.strip()
    for chat_id in os.environ.get("TELEGRAM_ALLOWED_CHAT_ID", "").split(",")
    if chat_id.strip()
}

# Haiku 4.5 does not support extended thinking / effort — omit both.
CLAUDE_MODEL = os.environ.get("CLAUDE_MODEL", "claude-haiku-4-5-20251001")

SYSTEM_PROMPT = (
    "Voce e o assistente pessoal de treino do usuario, focado em preparacao "
    "para Ironman. Nesta fase inicial voce ainda nao tem acesso aos dados de "
    "treino do Garmin nem a planilha de metricas — responda de forma direta "
    "e avise quando uma pergunta depender desses dados."
)

anthropic_client = anthropic.AsyncAnthropic()
http_client = httpx.AsyncClient(timeout=15.0)


@app.get("/")
async def health() -> dict:
    return {"status": "ok"}


@app.post("/webhook")
async def telegram_webhook(request: Request) -> Response:
    secret = request.headers.get("x-telegram-bot-api-secret-token", "")
    if not hmac.compare_digest(secret, TELEGRAM_WEBHOOK_SECRET):
        logger.warning("Rejected webhook call with invalid secret token")
        return Response(status_code=403)

    update = await request.json()
    message = update.get("message")
    if not message or "text" not in message:
        return Response(status_code=200)

    chat_id = str(message["chat"]["id"])
    if ALLOWED_CHAT_IDS and chat_id not in ALLOWED_CHAT_IDS:
        logger.warning("Ignored message from disallowed chat_id=%s", chat_id)
        return Response(status_code=200)

    reply_text = await ask_claude(message["text"])
    await send_telegram_message(chat_id, reply_text)
    return Response(status_code=200)


async def ask_claude(user_text: str) -> str:
    try:
        response = await anthropic_client.messages.create(
            model=CLAUDE_MODEL,
            # Telegram messages are capped at 4096 chars; no need for a large budget.
            max_tokens=1024,
            system=SYSTEM_PROMPT,
            messages=[{"role": "user", "content": user_text}],
        )
    except anthropic.RateLimitError:
        logger.exception("Anthropic API rate limited")
        return "Estou recebendo muitas mensagens agora, tenta de novo em instantes."
    except anthropic.APIStatusError as e:
        logger.exception("Anthropic API error (status=%s)", e.status_code)
        return "Tive um problema para gerar a resposta agora."
    except anthropic.APIConnectionError:
        logger.exception("Anthropic API connection error")
        return "Não consegui falar com a IA agora, tenta de novo."

    return next(
        (block.text for block in response.content if block.type == "text"),
        "(sem resposta de texto)",
    )


async def send_telegram_message(chat_id: str, text: str) -> None:
    response = await http_client.post(
        f"{TELEGRAM_API_URL}/sendMessage",
        json={"chat_id": chat_id, "text": text},
    )
    if response.status_code != 200:
        logger.error("Failed to send Telegram message: %s", response.text)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
