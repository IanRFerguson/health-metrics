from flask import Flask, render_template
from routes.api import bp as api_blueprint
from routes.webhook import bp as webhook_blueprint

from common.logger import metrics_logger

#####

server = Flask(
    __name__,
    static_folder="frontend/dist",
    static_url_path="/",
    template_folder="frontend/dist",
)
server.logger = metrics_logger


@server.route("/")
def index():
    return render_template("index.html")


server.register_blueprint(api_blueprint)
server.register_blueprint(webhook_blueprint)
