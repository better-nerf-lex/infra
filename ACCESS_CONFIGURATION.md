# Access Configuration Summary

## Current Setup (Kubernetes-like Ingress)

### Public ALB (Internet-Facing)
- **DNS**: `dev-alb-1430505080.eu-north-1.elb.amazonaws.com`
- **CloudFront**: `test-0.paragrafic.pl` → ALB
- **Ports**: 80 (redirect to 443), 443 (HTTPS)

### Routing Rules

| Path Pattern | Target | Access Level | URL |
|-------------|---------|--------------|-----|
| `/api/*`, `/api/gateway/*`, `/actuator/*` | **Gateway** | 🌍 Public | `https://test-0.paragrafic.pl/api/*` |
| ~~`/api/files/*`~~ | ~~File-service~~ | ❌ REMOVED | N/A |

### Service Access Matrix

| Service | Public Access | Internal Access | URL |
|---------|--------------|-----------------|-----|
| **Gateway** | ✅ Via ALB | ✅ Via Service Discovery | `https://test-0.paragrafic.pl/api/*`<br>`http://gateway.dev.paragrafic.local:8081` |
| **File-Service** | ❌ Not exposed | ✅ Via Service Discovery | `http://file-service.dev.paragrafic.local:8080` |

## How to Access

### Gateway (Public)
```bash
# Via CloudFront/ALB (public internet)
curl https://test-0.paragrafic.pl/api/actuator/health

# From within VPC (service discovery)
curl http://gateway.dev.paragrafic.local:8081/actuator/health
```

### File-Service (Internal Only)
```bash
# NOT accessible from public internet
# Only accessible from within VPC (e.g., from gateway)

# From gateway or other ECS tasks in same VPC:
curl http://file-service.dev.paragrafic.local:8080/files/upload

# From outside VPC: ❌ Not allowed
```

## Security Groups

### Gateway Security Group
- **Ingress**: ALB security group → Port 8081
- **Egress**: All traffic

### File-Service Security Group (Internal)
- **Ingress**: VPC CIDR (10.0.0.0/16) → Port 8080
- **Egress**: All traffic

### ALB Security Group
- **Ingress**: 0.0.0.0/0 → Port 80, 443
- **Egress**: All traffic

## Service Discovery (AWS Cloud Map)

Both services are registered in AWS Cloud Map namespace `dev.paragrafic.local`:

```
gateway.dev.paragrafic.local:8081
file-service.dev.paragrafic.local:8080
```

Resolution via Route 53 Private Hosted Zone (VPC internal DNS).

## Adding a New Public Service

To make a service publicly accessible via ALB:

1. **Add ALB listener rule** (`infra/modules/alb/main.tf`):
```hcl
resource "aws_lb_listener_rule" "new_service" {
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 103  # Next available priority
  
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.new_service.arn
  }
  
  condition {
    path_pattern {
      values = ["/api/newservice/*"]
    }
  }
}
```

2. **Pass target_group_arn** to service module
3. **Run `terraform apply`**

## Adding a New Internal Service

To make a service internal-only (like file-service):

1. **Don't create ALB listener rule**
2. **Don't pass `target_group_arn`** to service module
3. **Service automatically gets VPC ingress rule**
4. **Access via**: `http://service-name.dev.paragrafic.local:PORT`

## Testing

```bash
# Test gateway (public)
curl -I https://test-0.paragrafic.pl/api/actuator/health

# Test file-service routing removed (should get 404)
curl -I https://test-0.paragrafic.pl/api/files/test
# Expected: 404 (no route matches)

# Test from ECS exec into gateway container
aws ecs execute-command --cluster dev-cluster \
  --task $(aws ecs list-tasks --cluster dev-cluster --service dev-gateway --query 'taskArns[0]' --output text) \
  --container gateway \
  --command "curl http://file-service.dev.paragrafic.local:8080/" \
  --interactive
```

## Summary

✅ **Gateway**: Public via ALB  
✅ **File-service**: Internal only via Service Discovery  
✅ **Emulates Kubernetes Ingress**: Control which services are exposed  
✅ **Security**: Internal services not exposed to internet
