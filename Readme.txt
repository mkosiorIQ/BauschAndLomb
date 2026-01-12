
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
