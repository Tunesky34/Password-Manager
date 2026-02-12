# Kubernetes Deployment Issues - Fixed

## Issues Identified

### 1. Backend Pods Crashing (CrashLoopBackOff)
**Problem:** Backend pods unable to connect to MongoDB
**Root Cause:** Missing or incorrect Kubernetes secrets for database connection
**Status:** Requires manual intervention

**Fix Required:**
```bash
# Create the backend secrets with your actual values
kubectl create secret generic backend-secrets \
  --from-literal=PORT=5000 \
  --from-literal=DATABASE_URL='your-mongodb-connection-string' \
  --from-literal=CLERK_KEY='your-clerk-api-key' \
  --from-literal=ENCRYPTION_KEY='your-encryption-key'
```

### 2. Frontend Cannot Connect to Backend
**Problem:** Hardcoded `http://localhost:5000` in Dashboard.jsx
**Root Cause:** Frontend trying to reach backend on localhost instead of Kubernetes service
**Status:** ✅ FIXED

**Changes Made:**
- Updated Dashboard.jsx to use environment variable for API URL
- Created `.env.production` with backend service URL
- Added ConfigMap for frontend configuration
- Updated frontend deployment to inject VITE_API_URL

### 3. Service Naming Inconsistency
**Problem:** Multiple backend services and inconsistent naming
**Root Cause:** Duplicate service definitions
**Status:** ✅ FIXED

**Changes Made:**
- Renamed `frontend-service` to `password-frontend` for consistency
- Explicitly set backend service type to ClusterIP
- Removed duplicate backend service (keep only `password-backend`)

### 4. Missing Environment Configuration
**Problem:** Frontend not configured for Kubernetes environment
**Status:** ✅ FIXED

**Changes Made:**
- Created `frontend-configmap.yaml` for runtime configuration
- Updated `frontend-deployment.yaml` to use ConfigMap
- Added `.env.production` for build-time configuration

## Deployment Steps

### 1. Create Backend Secrets (REQUIRED)
```bash
kubectl create secret generic backend-secrets \
  --from-literal=PORT=5000 \
  --from-literal=DATABASE_URL='mongodb+srv://username:password@cluster.mongodb.net/dbname' \
  --from-literal=CLERK_KEY='your-clerk-api-key' \
  --from-literal=ENCRYPTION_KEY='your-32-character-encryption-key'
```

### 2. Delete Duplicate Backend Service
```bash
kubectl delete service backend-service
```

### 3. Apply Updated Configurations
```bash
# Apply ConfigMap
kubectl apply -f frontend-configmap.yaml

# Apply Services
kubectl apply -f backend-service.yaml
kubectl apply -f frontend-service.yaml

# Apply Deployments
kubectl apply -f backend-deployment.yml
kubectl apply -f frontend-deployment.yaml
```

### 4. Rebuild and Push Frontend Image (if needed)
Since we changed the frontend code, you need to rebuild:
```bash
# Build new frontend image
docker build -t tunesky34/password-manager-frontend:v4 .

# Push to registry
docker push tunesky34/password-manager-frontend:v4

# Update deployment to use new image
kubectl set image deployment/password-frontend frontend=tunesky34/password-manager-frontend:v4
```

### 5. Verify Deployment
```bash
# Check pods status
kubectl get pods

# Check services
kubectl get svc

# Check backend logs
kubectl logs -l app=password-backend

# Check frontend logs
kubectl logs -l app=password-frontend
```

### 6. Access the Application
```bash
# Get Minikube IP
minikube ip

# Access frontend at: http://<minikube-ip>:30008
```

## Architecture Overview

```
┌─────────────────┐
│   User Browser  │
└────────┬────────┘
         │ :30008 (NodePort)
         ▼
┌─────────────────────────┐
│  password-frontend svc  │
│    (NodePort: 30008)    │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Frontend Pods (x2)      │
│ Port: 80                │
└────────┬────────────────┘
         │ API calls to
         │ http://password-backend:5000
         ▼
┌─────────────────────────┐
│  password-backend svc   │
│    (ClusterIP: 5000)    │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Backend Pods (x2)       │
│ Port: 5000              │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│   MongoDB Atlas         │
│   (External)            │
└─────────────────────────┘
```

## Key Configuration Changes

### Dashboard.jsx
- Changed from: `http://localhost:5000/api/passwords`
- Changed to: `${import.meta.env.VITE_API_URL}/api/passwords`

### Frontend Deployment
- Added environment variable injection from ConfigMap
- VITE_API_URL points to `http://password-backend:5000`

### Services
- Backend: ClusterIP (internal only)
- Frontend: NodePort (external access on port 30008)

## Common Issues & Solutions

### Backend Still Crashing?
- Verify secrets exist: `kubectl get secrets`
- Check secret values: `kubectl describe secret backend-secrets`
- Verify MongoDB connection string is correct
- Check MongoDB Atlas network access allows Kubernetes cluster IP

### Frontend Can't Reach Backend?
- Verify backend service exists: `kubectl get svc password-backend`
- Check backend pods are running: `kubectl get pods -l app=password-backend`
- Verify frontend has correct env var: `kubectl exec -it <frontend-pod> -- env | grep VITE`

### Can't Access Frontend?
- Get Minikube IP: `minikube ip`
- Verify NodePort service: `kubectl get svc password-frontend`
- Check if port 30008 is accessible: `curl http://$(minikube ip):30008`

## Next Steps

1. ✅ Create backend secrets with your actual credentials
2. ✅ Delete duplicate backend-service
3. ✅ Apply all updated YAML files
4. ✅ Rebuild and push frontend image with new code
5. ✅ Update frontend deployment to use new image version
6. ✅ Verify all pods are running
7. ✅ Test application access
