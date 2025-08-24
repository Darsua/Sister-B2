import requests
import os

def post_request(url, data):
    try:
        response = requests.post(url, json=data)
        response.raise_for_status()  # Raise an error for bad responses
        return response.json()  # Return the JSON response
    except requests.exceptions.RequestException as e:
        print(f"An error occurred: {e}")
        return None

def get_request(url):
    try:
        response = requests.get(url)
        response.raise_for_status()  # Raise an error for bad responses
        return response.json()  # Return the JSON response
    except requests.exceptions.RequestException as e:
        print(f"An error occurred: {e}")
        return None

if __name__ == "__main__":
    response = None
    while True:
        os.system('clear')
        if response:
            print("--- Response ---")
            print(response, "\n")
            response = None
            print("MurinCoin Request Module")
            choice = input("1. POST a transcation\n2. GET started mining a new block\n3. Exit\nRequest what? (1-3) ")
            if choice == "1":
                sender = input("Sender: ")
                recipient = input("Recipient: ")
                amount = input("Amount: ")
                data = {
                    "sender": sender,
                    "recipient": recipient,
                    "amount": amount
                }
                response = post_request("http://localhost:5001/transaction", data)  
            elif choice == "2":
                response = get_request("http://localhost:5001/mine")
            elif choice == "3":
                print("Exiting...")
        break