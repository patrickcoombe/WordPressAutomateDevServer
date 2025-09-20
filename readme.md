# WordPress Docker Automation Script

This script automates the setup of a new WordPress environment for a client using Docker. It creates a complete, isolated WordPress stack with a database, phpMyAdmin, and an SFTP server. The entire process is containerized, ensuring a clean and repeatable deployment for each new client.

## Features

🏗️ **Automated Setup:** Quickly create a new WordPress instance for a client with a single command.
🐳 **Dockerized Environment:** Uses Docker Compose to manage a multi-container application, including WordPress, MySQL, phpMyAdmin, and SFTP.
🔐 **Secure by Default:** Automatically generates strong, unique passwords for the WordPress admin, MySQL database, and SFTP user.
📂 **Isolated Directories:** Each client's installation is stored in its own directory under `/opt/elite-wp-packages`, preventing conflicts.
⚙️ **WP-CLI Integration:** Installs and uses WP-CLI inside the container to automatically complete the WordPress installation.
📄 **Credential Management:** Saves all generated credentials to a `credentials.txt` file within the client's directory for easy access.

-----

## Prerequisites

  - **Docker:** The script requires Docker and Docker Compose to be installed on your system.
  - **WordPress Package:** A zipped WordPress package must be available at `/root/wp.zip`.
  - **Root Permissions:** The script must be run as the root user or with `sudo` to perform directory creation and Docker commands.

-----

## How to Use

1.  **Place the Script:** Save the provided script as `automateWordPress.sh` and place it in a convenient location.

2.  **Prepare the WordPress Zip:** Ensure you have a clean WordPress installation zipped and placed at `/root/wp.zip`.

3.  **Run the Script:** Execute the script from the command line. It will prompt you for a client name.

    ```bash
    sudo ./automateWordPress.sh
    ```

4.  **Enter Client Name:** When prompted, enter a client name without spaces and in lowercase (e.g., `client1`, `acme-corp`).

The script will then:

  - Create a directory for the client.
  - Unzip the WordPress package.
  - Create a `docker-compose.yml` file.
  - Start all the Docker containers.
  - Wait for the containers to be ready.
  - Install WordPress using WP-CLI and the generated credentials.
  - Save all access details to a `credentials.txt` file.

-----

## Post-Installation

After the script completes, you can find all the necessary access information in the `credentials.txt` file.

  - **WordPress Site URL:** `http://[client-name].elite04.com`
  - **phpMyAdmin URL:** `http://[client-name].elite04.com:8080`
  - **SFTP Access:**
      - **Host:** Your server's public IP address
      - **Port:** `2222`
      - **Username:** `[client-name]sftp`
  - **Credentials File Location:** `/opt/elite-wp-packages/[client-name]/credentials.txt`

-----

## Managing the Containers

The script provides convenient commands for managing the containers for a specific client.

  - **Stop and Remove Containers:**
    ```bash
    cd /opt/elite-wp-packages/[client-name]
    docker-compose down
    ```
  - **View Logs:**
    ```bash
    cd /opt/elite-wp-packages/[client-name]
    docker-compose logs -f
    ```

-----

## Directory Structure

The script creates the following directory structure for each client:

```
/opt/elite-wp-packages/
└── [client-name]/
    ├── html/               # All WordPress files are here
    ├── docker-compose.yml  # Docker configuration for this client
    └── credentials.txt     # All generated credentials

```
