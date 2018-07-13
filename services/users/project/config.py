import os
import sys

class BaseConfig:
    """Base configuration"""
    TESTING = False
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SECRET_KEY = 'my_precious'

class DevelopmentConfig(BaseConfig):
    """Development configuration"""

    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL')
    print('SQLALCHEMY_DATABASE_URI', file=sys.stderr)
    print(SQLALCHEMY_DATABASE_URI, file=sys.stderr)
    pass

class TestingConfig(BaseConfig):
    """Testing Configuration"""
    TESTING = True
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL')


class ProductionConfig(BaseConfig):
    """Production Configuration"""
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL')
    pass
