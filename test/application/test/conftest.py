
def pytest_addoption(parser):
    parser.addoption("--pass", action="store_true", help="Test option", required=True)
