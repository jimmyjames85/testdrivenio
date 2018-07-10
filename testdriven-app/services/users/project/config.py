class BaseConfig:
    """Base configuration"""
    TESTING = False


class DevelopmentConfig(BaseConfig):
    """Development configuration"""
    pass

class TestingConfig(BaseConfig):
    """Testing Configuration"""
    TESTING = True


class ProductionConfig(BaseConfig):
    """Production Configuration"""
    pass
