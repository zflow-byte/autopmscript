########################################
# Python Script DellOS 10 Backup
# Creator : Wish Enterprise Group Co., Ltd.
# Create Date : 2 Sep 2023
# Version : 1
########################################

import argparse
import os
from netmiko import ConnectHandler
import datetime

def backup_dell_switch(ip, username, password, enable_secret, path):
    device = {
        'device_type': 'dell_os10_ssh',
        'ip': ip,
        'username': username,
        'password': password,
        'port': 22,
        'secret': enable_secret,
    }

    connection = ConnectHandler(**device)
    connection.enable()

    hostname = connection.send_command_timing('show running-configuration | grep hostname', read_timeout=5)
    hostname = hostname.strip().split()[-1]

    backup_time = datetime.datetime.now().strftime("%Y%m%d%H%M")
    backup_file = os.path.join(path, f"{hostname}_backup_{backup_time}.txt")
    output = connection.send_command("show running-configuration")

    with open(backup_file, 'w') as file:
        file.write(output)

    connection.disconnect()
    print(f"The backup is completed... {backup_file}")

def main():
    parser = argparse.ArgumentParser(description='The Script for backup Dell switch OS10 Only')
    parser.add_argument('--ip', required=True, help='IP Address Dell switch')
    parser.add_argument('--username', required=True, help='Username SSH')
    parser.add_argument('--password', required=True, help='Password SSH')
    parser.add_argument('--enable-secret', help='Password enable mode')
    parser.add_argument('--path', required=True, help='Path')

    args = parser.parse_args()

    backup_dell_switch(args.ip, args.username, args.password, args.enable_secret, args.path)

if __name__ == "__main__":
    main()
