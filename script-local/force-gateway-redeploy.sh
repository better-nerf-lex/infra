#!/bin/bash
aws ecs update-service --cluster dev-cluster --service dev-gateway --force-new-deployment --region eu-north-1
