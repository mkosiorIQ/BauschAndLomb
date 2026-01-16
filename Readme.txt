
Step 1: Create a GitHub Repository
    1. Navigate to GitHub and sign in.
    2. In the upper-right corner, click the + icon and select New repository.
    3. Enter a repository name (e.g., github-actions-demo), choose visibility (Public/Private),
       and optionally select Add a README file.
    4. Click Create repository.

Step 2: Push your local code (if applicable) 
If you have existing code locally, link it to your new GitHub repository using the following
Git commands in your terminal, replacing the URL with your repository's actual URL:
    git init
    git add .
    git commit -m "Initial commit"
    git remote add origin https://github.com/USERNAME/REPOSITORY_NAME.git
    git push origin main
    git pull origin main
Step 3: In repro create a folder ./githib/workflows/
Step 4: In the folder create a YAML file with .yml extension


-----------------------------------------------------------------------------
Test on a "committed" file
gh workflow run "Deploy Terraform" --ref main
    the file with 'name: Deploy Terraform' must be committed
gh run list --workflow="deploy-terraform.yml"
gh run view 20928730072 --log
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
Test on a github workflow locally on windows before a commit
Note act uses Docker
act -P windows-latest=-self-hosted -j terraform-plan

Remove locked directories under act
C:\Users\mkosior\.cache\act

export AZURE_SP_CREDENTIALS='{ "clientId": "...", "clientSecret": "...", "subscriptionId": "...", "tenantId": "..." }'
export AZURE_SP_CREDENTIALS='{ "subscriptionId": "046696af-1d89-4ff1-9ab1-411f666c1c06", "tenantId": "38e87a3b-2695-4888-9f38-f0feeed23c9f", "clientId": "3fc42ced-ec65-49ff-a5fa-548b14649804", "clientSecret": "je18Q~VJ2kGR6tBmySfHZwrojD6DOPoYOsDgrdwc" }'
act -s AZURE_SP_CREDENTIALS
Directly in command
act -s AZURE_SP_CREDENTIALS='{ "subscriptionId": "046696af-1d89-4ff1-9ab1-411f666c1c06", "tenantId": "38e87a3b-2695-4888-9f38-f0feeed23c9f", "clientId": "3fc42ced-ec65-49ff-a5fa-548b14649804", "clientSecret": "je18Q~VJ2kGR6tBmySfHZwrojD6DOPoYOsDgrdwc" }'
For sXecrets in your repository root or a secure location

act -P windows-latest=-self-hosted --sXecret-file .secrets -j terraform-plan
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
To run Terraform in the terraform directory
$env:ARM_SUBSCRIPTION_ID = "046696af-1d89-4ff1-9ab1-411f666c1c06"
$env:ARM_TENANT_ID = "38e87a3b-2695-4888-9f38-f0feeed23c9f"
$env:ARM_CLIENT_ID = "3fc42ced-ec65-49ff-a5fa-548b14649804"
$env:ARM_CLIENT_SECRET = "je18Q~VJ2kGR6tBmySfHZwrojD6DOPoYOsDgrdwc"

$env:TF_VAR_SUBSCRIPTION_ID = "046696af-1d89-4ff1-9ab1-411f666c1c06"
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
May need az login to be able to pass two stage authentication.
-----------------------------------------------------------------------------

Build a Client Server to display in real time events received by the event hub
- The front end is a web UI 
- Using React 18+ with TypeScript for medical device reliability
- Azure SignalR Service will be used for live telemetry
- Tailwind CSS for rapid and consistent UI design