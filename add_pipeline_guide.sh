#!/bin/bash

# NixOS Fabric CI/CD Pipeline Addition Guide
# This script provides step-by-step instructions to add the CI/CD pipeline workflow
# to the repository using the GitHub web interface

echo "🚀 NixOS Fabric CI/CD Pipeline Addition Guide"
echo "============================================"
echo ""

echo "Since we cannot push the workflow file directly due to GitHub token permissions,"
echo "this guide will help you add it manually through the GitHub web interface."
echo ""

echo "Step 1: Prepare the workflow file"
echo "----------------------------------"
echo "The workflow file has been saved to: .github/workflows/ci-cd-pipeline.yml"
echo ""

# Check if the file exists
if [ -f ".github/workflows/ci-cd-pipeline.yml" ]; then
    echo "✅ Workflow file exists and is ready"
    echo ""
    echo "File location: $(pwd)/.github/workflows/ci-cd-pipeline.yml"
    echo "File size: $(wc -c < .github/workflows/ci-cd-pipeline.yml) bytes"
    echo ""
else
    echo "❌ Workflow file not found!"
    echo "Please ensure the file exists at .github/workflows/ci-cd-pipeline.yml"
    exit 1
fi

echo "Step 2: Open GitHub repository"
echo "-------------------------------"
echo "Open your web browser and navigate to:"
echo "https://github.com/franck01081991/nixos-fabric"
echo ""

echo "Step 3: Navigate to workflows directory"
echo "----------------------------------------"
echo "1. Click on '.github' folder"
echo "2. Click on 'workflows' folder"
echo "3. You should see the current workflows"
echo ""

echo "Step 4: Upload the workflow file"
echo "---------------------------------"
echo "1. Click on 'Add file' button (top right)"
echo "2. Select 'Upload files'"
echo "3. Drag and drop the ci-cd-pipeline.yml file"
echo "   OR click 'choose your files' and select it"
echo ""

echo "Step 5: Commit the file"
echo "------------------------"
echo "1. Add a commit message:"
echo "   'feat(ci-cd): add comprehensive CI/CD pipeline workflow'"
echo "2. Select 'Commit directly to the master branch'"
echo "3. Click 'Commit changes'"
echo ""

echo "Step 6: Verify the pipeline"
echo "---------------------------"
echo "1. Go to 'Actions' tab in your repository"
echo "2. You should see the new 'NixOS Fabric CI/CD Pipeline'"
echo "3. The pipeline should run automatically on the next push"
echo ""

echo "Alternative Method: Using GitHub CLI"
echo "-------------------------------------"
echo "If you have GitHub CLI (gh) installed, you can use:"
echo ""
echo "  gh auth login"
echo "  gh repo clone franck01081991/nixos-fabric"
echo "  cd nixos-fabric"
echo "  # Copy the workflow file to the clone"
echo "  cp /path/to/ci-cd-pipeline.yml .github/workflows/"
echo "  gh repo push"
echo ""

echo "Alternative Method: Create a Pull Request"
echo "-----------------------------------------"
echo "  git checkout -b feature/add-ci-cd-pipeline"
echo "  git add .github/workflows/ci-cd-pipeline.yml"
echo "  git commit -m 'feat(ci-cd): add comprehensive CI/CD pipeline workflow'"
echo "  git push origin feature/add-ci-cd-pipeline"
echo "  # Then create a PR on GitHub and merge it"
echo ""

echo "Pipeline Features Summary"
echo "------------------------"
echo "The CI/CD pipeline includes 9 comprehensive jobs:"
echo "  1. Validate Repository Structure"
echo "  2. Validate Security Module"
echo "  3. Validate Configurations"
echo "  4. Build Configurations"
echo "  5. Test Security Features"
echo "  6. Test Module Integration"
echo "  7. Prepare Deployment"
echo "  8. Validate Documentation"
echo "  9. Final Validation"
echo ""

echo "The pipeline provides:"
echo "  ✅ Comprehensive validation at every stage"
echo "  ✅ Security-focused testing"
echo "  ✅ Complete documentation validation"
echo "  ✅ Deployment-ready artifacts"
echo "  ✅ Clear reporting and success criteria"
echo ""

echo "Once added, the pipeline will automatically:"
echo "  - Run on every push to master"
echo "  - Run on every pull request to master"
echo "  - Validate repository structure"
echo "  - Test security module"
echo "  - Build all configurations"
echo "  - Prepare deployment artifacts"
echo "  - Validate documentation"
echo ""

echo "🎉 Ready to add the pipeline!"
echo "================================"
echo ""
echo "The workflow file is ready at:"
echo "$(pwd)/.github/workflows/ci-cd-pipeline.yml"
echo ""
echo "Follow the steps above to add it to your repository."
echo "Once added, your NixOS Fabric repository will have a complete"
echo "CI/CD pipeline for validation, testing, and deployment!"
echo ""

# Show file info
ls -lh .github/workflows/ci-cd-pipeline.yml
echo ""
echo "File content preview (first 20 lines):"
echo "========================================"
head -20 .github/workflows/ci-cd-pipeline.yml
echo ""
echo "========================================"
echo ""

echo "Need help?"
echo "----------"
echo "If you encounter any issues, check:"
echo "  • File permissions (should be readable)"
echo "  • File location (should be in .github/workflows/)"
echo "  • GitHub repository access"
echo ""
echo "For questions, refer to:"
echo "  • .github/CI-CD-PIPELINE.md (pipeline documentation)"
echo "  • DEPLOYMENT_SUMMARY.md (deployment summary)"
echo "  • PIPELINE_IMPROVEMENTS.md (pipeline improvements)"
echo ""

exit 0