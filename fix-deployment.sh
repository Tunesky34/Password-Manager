#!/bin/bash

echo "🔧 Fixing Kubernetes Deployment Issues..."
echo ""

# Step 1: Delete duplicate backend service if exists
echo "1️⃣ Cleaning up duplicate services..."
kubectl delete service backend-service 2>/dev/null || echo "   No duplicate backend-service found (OK)"
kubectl delete service frontend-service 2>/dev/null || echo "   Deleting old frontend-service..."

# Step 2: Apply ConfigMap
echo ""
echo "2️⃣ Creating frontend ConfigMap..."
kubectl apply -f frontend-configmap.yaml

# Step 3: Apply Services
echo ""
echo "3️⃣ Applying service configurations..."
kubectl apply -f backend-service.yaml
kubectl apply -f frontend-service.yaml

# Step 4: Apply Deployments
echo ""
echo "4️⃣ Applying deployment configurations..."
kubectl apply -f backend-deployment.yml
kubectl apply -f frontend-deployment.yaml

# Step 5: Wait for rollout
echo ""
echo "5️⃣ Waiting for deployments to roll out..."
kubectl rollout status deployment/password-backend --timeout=120s
kubectl rollout status deployment/password-frontend --timeout=120s

# Step 6: Show status
echo ""
echo "6️⃣ Current Status:"
echo "=================="
kubectl get pods -o wide
echo ""
kubectl get svc
echo ""

# Step 7: Check backend logs
echo "7️⃣ Backend Pod Logs (last 10 lines):"
echo "====================================="
BACKEND_POD=$(kubectl get pods -l app=password-backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ ! -z "$BACKEND_POD" ]; then
    kubectl logs $BACKEND_POD --tail=10 2>&1 || echo "Backend pod not ready yet"
else
    echo "No backend pod found"
fi

echo ""
echo "✅ Deployment update complete!"
echo ""
echo "📝 Next Steps:"
echo "   1. Verify backend pods are running (not CrashLoopBackOff)"
echo "   2. If backend still crashes, check MongoDB connection"
echo "   3. Rebuild frontend image with updated code:"
echo "      docker build -t tunesky34/password-manager-frontend:v4 ."
echo "      docker push tunesky34/password-manager-frontend:v4"
echo "      kubectl set image deployment/password-frontend frontend=tunesky34/password-manager-frontend:v4"
echo ""
echo "🌐 Access frontend at: http://$(minikube ip 2>/dev/null || echo '<minikube-ip>'):30008"
