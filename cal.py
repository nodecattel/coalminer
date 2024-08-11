#!/usr/bin/env python3

import subprocess
import requests
from colorama import Fore, Style, init
from tabulate import tabulate

# Initialize colorama
init(autoreset=True)

# Define the API key for BirdEye
api_key = "77c5257736a248988068353d034280b0"

# Define the token addresses
sol_address = "So11111111111111111111111111111111111111112"
ore_address = "oreoU2P8bN6jkk3jbaiVxYnG1dCXcYxwhwyK9jSybcp"

def get_token_price(address):
    url = f"https://public-api.birdeye.so/defi/price?address={address}"
    headers = {"X-API-KEY": api_key}
    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        data = response.json().get('data', {})
        return data.get('value')
    else:
        print(f"Failed to fetch price for address {address}")
        return None

def get_ore_binary_path():
    try:
        result = subprocess.run(['which', 'ore'], capture_output=True, text=True)
        ore_path = result.stdout.strip()
        print(f"ORE binary path: {ore_path}")  # Debug print
        return ore_path
    except Exception as e:
        print(f"Failed to find `ore` binary path: {e}")
        return None

def get_ore_rewards(ore_path):
    try:
        result = subprocess.run([ore_path, 'rewards'], capture_output=True, text=True)
        output = result.stdout.strip()
        print("ORE rewards output:", output)  # Debug print
        rewards = {}
        
        for line in output.split('\n'):
            parts = line.split(': ')
            if len(parts) == 2:
                difficulty = int(parts[0])
                reward = float(parts[1].split()[0])
                rewards[difficulty] = reward
        
        return rewards
    except Exception as e:
        print(f"Failed to execute `ore rewards`: {e}")
        return {}

def display_rewards_in_usd_per_hour(rewards, ore_price, priority_fees_lamports, sol_price, electric_cost_per_hour):
    ore_mining_fee_lamports = 5000
    rewards_usd_per_hour = {difficulty: round(reward * ore_price * 60, 8) for difficulty, reward in rewards.items()}
    table = []

    for difficulty, reward in rewards.items():
        reward_usd_per_hour = rewards_usd_per_hour[difficulty]
        total_fee_lamports_per_hour = (priority_fees_lamports + ore_mining_fee_lamports) * 60
        total_fee_sol_per_hour = total_fee_lamports_per_hour / 1e9
        total_fee_usd_per_hour = total_fee_sol_per_hour * sol_price + electric_cost_per_hour
        profit_usd_per_hour = reward_usd_per_hour - total_fee_usd_per_hour
        profitable = "Yes" if profit_usd_per_hour > 0 else "No"
        table.append([difficulty, reward, reward_usd_per_hour, total_fee_usd_per_hour, profit_usd_per_hour, profitable])

    print(tabulate(table, headers=["Difficulty", "ORE Reward (per min)", "USD Reward (per hour)", "Total Fee (USD/hour)", "Profit (USD/hour)", "Profitable"], tablefmt="pretty"))
    return rewards_usd_per_hour

def calculate_profitability(priority_fees_lamports, average_difficulty, rewards, sol_price, ore_price, electric_cost_per_hour):
    ore_mining_fee_lamports = 5000
    total_fee_lamports = priority_fees_lamports + ore_mining_fee_lamports
    total_fee_sol = total_fee_lamports / 1e9
    total_fee_usd = total_fee_sol * sol_price + electric_cost_per_hour
    
    reward_ore = rewards.get(average_difficulty, 0)
    reward_usd = round(reward_ore * ore_price * 60, 8)
    
    profit_usd_per_hour = reward_usd - total_fee_usd
    total_fee_sol_per_hour = total_fee_sol * 60
    
    return total_fee_usd, reward_usd, profit_usd_per_hour, total_fee_sol_per_hour, reward_ore

def main():
    sol_price = get_token_price(sol_address)
    ore_price = get_token_price(ore_address)
    print(f"SOL Price: {sol_price}, ORE Price: {ore_price}")
    if sol_price is None or ore_price is None:
        return
    
    ore_path = get_ore_binary_path()
    if not ore_path:
        return
    
    rewards = get_ore_rewards(ore_path)
    if not rewards:
        return
    
    print(Fore.GREEN + "Enter your priority fees in microlamports: ", end="")
    priority_fees_lamports = int(input())
    print(Fore.GREEN + "Enter the average landing difficulty: ", end="")
    average_difficulty = int(input())
    print(Fore.GREEN + "Enter your electric/rental fees per hour in USD: ", end="")
    electric_cost_per_hour = float(input())

    rewards_usd_per_hour = display_rewards_in_usd_per_hour(rewards, ore_price, priority_fees_lamports, sol_price, electric_cost_per_hour)
    
    total_fee_usd, reward_usd, profit_usd_per_hour, total_fee_sol_per_hour, reward_ore = calculate_profitability(priority_fees_lamports, average_difficulty, rewards, sol_price, ore_price, electric_cost_per_hour)
    
    # Detailed breakdown
    print(Fore.CYAN + "\nCost Breakdown:")
    print(f"{Fore.YELLOW}SOL Price: {Fore.RESET}${sol_price:.2f}")
    print(f"{Fore.YELLOW}ORE Price: {Fore.RESET}${ore_price:.2f}")
    print(f"{Fore.YELLOW}Priority Fees: {Fore.RESET}{priority_fees_lamports / 1e6:.6f} SOL")
    print(f"{Fore.YELLOW}ORE Mining Fee: {Fore.RESET}0.000300 SOL")
    print(f"{Fore.YELLOW}Electric/Rental Fees: {Fore.RESET}${electric_cost_per_hour:.2f} per hour")
    
    print(Fore.CYAN + "\nSummary:")
    print(f"Total Mining Fee per hour: {Fore.RED}{total_fee_sol_per_hour:.6f} SOL {Fore.RESET}| {Fore.RED}${total_fee_usd:.6f}")
    print(f"ORE Reward per hour: {Fore.GREEN}{reward_ore * 60:.8f} ORE {Fore.RESET}| {Fore.GREEN}${reward_usd:.6f}")
    
    daily_profit_usd = profit_usd_per_hour * 24
    print(f"Daily Profit (USD): {Fore.GREEN if daily_profit_usd >= 0 else Fore.RED}${daily_profit_usd:.6f}")

    if profit_usd_per_hour >= 0:
        print(Fore.GREEN + f"Profit (USD/hour): ${profit_usd_per_hour:.6f}")
    else:
        print(Fore.RED + f"Profit (USD/hour): ${profit_usd_per_hour:.6f}")

if __name__ == "__main__":
    main()
