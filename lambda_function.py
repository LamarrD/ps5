from selenium import webdriver
from selenium.webdriver.common.by import By
import json
import boto3
import os


def get_driver(local):
    driver = None
    if local:
        driver = webdriver.Chrome()
    else:
        from headless_chrome import create_driver
        driver = create_driver()
    return driver


def notify(retailer, link):
    print("Texting Everyone!")
    sns = boto3.client('sns')
    sns.publish(
        TopicArn=os.environ['SNS_TOPIC'],
        Message=f'PS5 is in stock from {retailer} at {link} !',
    )


def is_stock_available(store_config, local_execution):
    print("Checking stock")
    driver = get_driver(local_execution)
    driver.get(store_config['link'])
    add_to_cart = driver.find_element(By.XPATH, store_config['xpath'])
    return add_to_cart.text == store_config["button_text"]


def lambda_handler(event, context):
    retailer = event['retailer']
    print(f"Running notifier for: {retailer}")
    store_config = json.load(open("store_config.json"))

    local_execution = context == {}
    in_stock = is_stock_available(store_config, local_execution)
    if in_stock:
        notify(retailer, store_config['link'])
    

if __name__ == "__main__":
    lambda_handler({"retailer": "bestbuy"}, {})