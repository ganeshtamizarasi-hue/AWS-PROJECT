# Screenshots Upload Guide

Upload your screenshots with these EXACT filenames
so they render correctly in README.md

## Required Screenshots (15 total)

| Filename | What to Screenshot | Where to Find |
|---|---|---|
| 01-vpc.png | VPC overview page | EC2 → VPC → Your VPCs |
| 02-subnets.png | All 4 subnets listed | VPC → Subnets |
| 03-security-groups.png | All 4 SGs listed | VPC → Security Groups |
| 04-rds.png | RDS instance "Available" | RDS → Databases |
| 05-efs.png | EFS file system | EFS → File systems |
| 06-secrets-manager.png | Secret with retrieved value | Secrets Manager |
| 07-alb.png | ALB "Active" status | EC2 → Load Balancers |
| 08-asg.png | ASG with 2 instances | EC2 → Auto Scaling Groups |
| 09-target-groups.png | Both TGs showing Healthy | EC2 → Target Groups |
| 10-ecr.png | ECR repo with image tag | ECR → Repositories |
| 11-codepipeline-green.png | All 3 stages green | CodePipeline |
| 12-codedeploy-bluegreen.png | Deployment succeeded | CodeDeploy → Deployments |
| 13-wordpress-live.png | ganeshc.shop in browser | Open ganeshc.shop |
| 14-cloudwatch.png | CloudWatch alarms | CloudWatch → Alarms |
| 15-route53.png | Route53 records | Route53 → Hosted zones |

## Tips for Good Screenshots
- Use full browser window (not zoomed in)
- Make sure status shows clearly (Available, Active, Healthy)
- For WordPress screenshot — show the full browser with URL bar showing ganeshc.shop
- For CodePipeline — show all 3 stages (Source, Build, Deploy) all green
