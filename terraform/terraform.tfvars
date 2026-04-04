# ═══════════════════════════════════════════════════════════════
# terraform.tfvars
# ⚠️  NEVER push this file to GitHub — it's in .gitignore
# ═══════════════════════════════════════════════════════════════

db_password = "prodadm123"

acm_certificate_arn = "arn:aws:acm:ap-south-1:145400477094:certificate/9a37a51b-80df-4de1-95f3-db6031d5897e"

acm_certificate_arn_us_east_1 = "arn:aws:acm:us-east-1:145400477094:certificate/d0f9fb5e-5776-4b7d-9e8a-1698562995aa"

# Get this from: AWS Console → CodePipeline → Settings → Connections
# Create connection → GitHub → Authorize → Copy ARN
github_connection_arn = "arn:aws:codestar-connections:ap-south-1:145400477094:connection/REPLACE-WITH-YOUR-CONNECTION-ID"

github_repo = "ganeshtamizarasi-hue/aws-wordpress-prod-dr-project"
