# impact-installation-script

Installation script for the impact analysis

## Linux

Arcan Impact Analysis installation script for Linux

### With `wget`

```bash
wget -q https://raw.githubusercontent.com/Arcan-Tech/impact-installation-script/refs/heads/master/install.sh && chmod +x ./install.sh && ./install.sh
```

### With `curl`

```bash
curl -O -s https://raw.githubusercontent.com/Arcan-Tech/impact-installation-script/refs/heads/master/install.sh && chmod +x ./install.sh && ./install.sh
```

## On Windows (Git-Bash)

Arcan Impact Analysis installation script for Windows

```bash
TODO
```

# Requirements

- Bash & wget (installation)
- Running Docker Engine >20.10
- At least 4 CPU cores (preferably 6+)
- At least 16GB of RAM
- At least 30 GB of disk space for images and space for analyses

# Installation

To start the installation run the `./install.sh` script, the script will guide you through.

The first prompt will ask your registry token to pull the images, without this step you won't be able to pull the images. If you don't have any token please contact us.
This will generate a configuration file that will be used by run-impact.sh without altering the machine's docker credentials.

The next prompt will ask you to configure the impact analysis

## Configuration

At the current state the express option it is the fastest option to install and serve the tool locally with the latest stable version. It will serve the application over HTTP, enables the auto updater and use the directory "./repos" for local analyses

The custom option will prompt with the following settings:

- Version: At the current state is only possible to use latest or snapshot. Latest is the most recent stable version of the tool, the snapshot is the most recent unstable.
- Protocol: If you wish to serve the application only over HTTPS you can set HTTPS, otherwise use HTTP
- Auto updater: Enable this to automatically update images every 2 hours, if valid credentials are available.
  > **_Warning:_** Using the auto-updater with the snapshot version may compromise your deployed application and data
- Repository directory: Specify the path to local repositories on your machine. Ensure the path is correct; otherwise, local analysis will fail.
- Ip: Define the IP address to serve the tool's web interface and API.

Before completing the configuration you will be showed a summary and you will be asked to confirm, if you choose to not confirm the configuration step will start over

## Launch the tool

Once the installation is completed you should see a message saying so and the address where you can access the tool. It should be < protocol you set >://< IP you set >:3000, e.g. http://192.168.1.8:3000

you can launch the tool with `./run-impact.sh`, once all the containers have launched you can access the tool

## Use the tool

### **First-Time Setup**

- When you first launch the tool, no users will exist. You must create a user account.
- User accounts are only used to associate projects and repositories.
  > **Note:** Password recovery is not implemented, so keep your credentials secure.

### Local analysis

To perform a local analysis:

1. Add a repository:
   - Select the **Local** option.
   - Enter the repository name in the input below.
2. Ensure the repository is cloned into the `./repos` folder (default for Express mode) or the directory specified during configuration.
   > **Example:**  
   > If your repository is named `my-repo`, clone it into the `./repos` directory:  
   > `git clone https://github.com/user/my-repo ./repos/my-repo`.
3. Ensure the branches to analyzed have been fetched, add those you wish to analyze

### Remote analysis

1. Add a repository:
   - Select the **Remote** option.
   - Enter the repository URL (e.g., `https://github.com/user/repository`) on the input below.
2. All availables branches will be fetched, add those you wish to analyze

Private repositories must be analyzed locally due to access restrictions.

### Analysis

After creating at least one repository in a project you will be able to perform an analysis by clicking the button "Request new analysis", most of the field will be already filled. If you added more than 1 branch in any of the repositories you will have to select it

### ** Other Notes**

- Docker must be installed and running before starting the installation.
- HTTPS requires valid certificates to function correctly.
