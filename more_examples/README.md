# More Workflow Scripts
The example workflow scripts in this folder can be uploaded directly into the SocketXP artifact registry as "script" type artifact.  This approach is useful, if you use a third-party artifact registry or your own private registry to store your build artifacts.  

You can directly upload the workflow script to the SocketXP registry (without having to build a `tar.gz` file) and deploy OTA updates using the script.  The script will in-turn download the required artifacts from your private or third-party registry, as per the instructions in your workflow script.
