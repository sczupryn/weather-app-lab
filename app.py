from flask import Flask, render_template, request
import requests
import os
from datetime import datetime
from typing import Any, Optional
from dotenv import load_dotenv

app = Flask(__name__)

load_dotenv()

AUTHOR: str = os.getenv("AUTHOR")
PORT: int = int(os.getenv("FLASK_PORT", 5000))
API_KEY: str = os.getenv("WEATHER_API_KEY")

LOCATIONS: dict[str, list[str]] = {
    "Polska": ["Warszawa", "Kraków", "Gdańsk"],
    "Czechy": ["Praga", "Ostrawa", "Brno"],
    "Niemcy": ["Berlin", "Hamburg", "Schwerin"],
}


def get_weather(city: str) -> Optional[dict[str, Any]]:
    url: str = (
        f"https://api.openweathermap.org/data/2.5/weather?q={city}&appid={API_KEY}&units=metric&lang=pl"
    )
    response = requests.get(url)
    if response.status_code == 200:
        return response.json()
    return None


with app.app_context():
    print(f"Aplikacja uruchomiona: {datetime.now()}")
    print(f"Autor: {AUTHOR}")
    print(f"Port: {PORT}")


@app.route("/", methods=["GET", "POST"])
def index():
    weather_data = None
    selected_country = request.args.get("country")
    selected_city = None

    if request.method == "POST":
        selected_country = request.form["country"]
        selected_city = request.form["city"]
        weather_data = get_weather(selected_city)

    return render_template(
        "index.html",
        locations=LOCATIONS,
        weather=weather_data,
        selected_country=selected_country,
        selected_city=selected_city,
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT)
