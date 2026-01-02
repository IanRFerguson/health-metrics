from flask import Flask
from routes.api import bp as api_blueprint
from routes.webhook import bp as webhook_blueprint

from common.logger import logger

#####

server = Flask(__name__)
server.logger = logger

server.register_blueprint(api_blueprint)
server.register_blueprint(webhook_blueprint)
