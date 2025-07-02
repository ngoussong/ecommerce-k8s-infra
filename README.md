# E-Commerce Website on Kubernetes (EKS) – Full Deployment Guide

This documentation provides a step-by-step walkthrough of deploying a containerized e-commerce web application and its MariaDB database backend on AWS EKS using Kubernetes. This project highlights proficiency in Kubernetes and containerization, demonstrating the ability to deploy, scale, and manage web applications efficiently in a K8s environment, underscoring cloud-native deployment skills.

---

## 📦 Project Overview

- **Frontend**: PHP-based e-commerce website
- **Backend**: MariaDB database
- **Platform**: AWS EKS (Elastic Kubernetes Service)
- **CI/CD**: Manual Docker image builds and `kubectl` apply

---

## 🚀 Step-by-Step Deployment Guide with Solutions

### Step 1: Set Up AWS EKS Cluster

**Task:** Create and configure EKS cluster with `kubectl` access.

**Solution:**

- Created EKS cluster manually or via `eksctl`.
- Verified cluster with `kubectl get svc`.
- Ensured role-based access was mapped in `aws-auth` ConfigMap.

---

### Step 2: Containerize Web App and Database

#### A. Web Application

**Task:** Containerize the PHP application.

**Solution:**

- Created a Dockerfile:
  ```dockerfile
  FROM php:7.4-apache
  RUN docker-php-ext-install mysqli
  COPY . /var/www/html/
  EXPOSE 80
  ```
- Updated code to use `mysql-service` as DB host.
- Built image: `docker build -t yourdockerhubusername/ecom-web:v1 .`

#### B. Database Initialization

**Task:** Use official MariaDB image and load data via SQL script.

**Solution:**

- Created `db-load-script.sql` with schema + data.
- Created a ConfigMap to hold the SQL file:
  ```bash
  kubectl create configmap db-init-script --from-file=db-load-script.sql
  ```
- Mounted it into `/docker-entrypoint-initdb.d/` in MariaDB deployment.

---

### Step 3: Build & Push Docker Images

**Task:** Publish the Docker image.

**Solution:**

```bash
docker build -t yourdockerhubusername/ecom-web:v1 .
docker push yourdockerhubusername/ecom-web:v1
```

---

### Step 4: Kubernetes Deployments

#### A. MariaDB Deployment

**Task:** Deploy the DB with init data.

**Solution:**

- Used `mariadb:10.6` image.
- Injected DB env vars from ConfigMap.
- Mounted SQL script from same ConfigMap.

#### B. Web Application Deployment

**Task:** Deploy the app with correct environment config.

**Solution:**

- Referenced Docker image `ecom-web:v1`.
- Used ConfigMap and Secret for DB env vars.

---

### Step 5: Services

**Task:** Make app and DB reachable.

**Solution:**

- `mysql-service`: ClusterIP to expose DB to internal pods.
- `ecom-web-service`: LoadBalancer to expose website to the internet.

---

### Step 6: Rolling Updates

**Task:** Deploy a new version of the app (v2).

**Solution:**

- Modified UI to include promo banner.
- Rebuilt image as `ecom-web:v2` and pushed it.
- Updated deployment image tag and applied:
  ```bash
  kubectl apply -f website-deployment.yaml
  ```
- Verified with `kubectl rollout status deployment/ecom-web`

---

### Step 7: Rollbacks

**Task:** Revert app due to bug in promo update.

**Solution:**

```bash
kubectl rollout undo deployment/ecom-web
```

- Restored image to previous version (`v1`)

---

### Step 8: Scaling and HPA

**Task:** Scale up for marketing campaign.

**Solution:**

- Manually scaled:
  ```bash
  kubectl scale deployment ecom-web --replicas=6
  ```
- Created autoscaler:
  ```bash
  kubectl autoscale deployment ecom-web --cpu-percent=50 --min=2 --max=10
  ```
- Simulated load with Apache Bench.

---

### Step 9: Probes

**Task:** Add health checks to restart or delay pods as needed.

**Solution:**

```yaml
livenessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 10
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 2
```

- Simulated failure to verify pod restart.

---

### Step 10: Secrets and ConfigMaps

**Task:** Externalize and secure DB config.

**Solution:**

- Created ConfigMap:
  ```bash
  kubectl create configmap app-config \
    --from-literal=DB_HOST=mysql-service \
    --from-literal=DB_NAME=ecomdb \
    --from-literal=FEATURE_PROMO_BANNER=true
  ```
- Created Secret:
  ```bash
  kubectl create secret generic db-secret \
    --from-literal=DB_USER=ecomuser \
    --from-literal=DB_PASSWORD=ecompassword
  ```
- Injected values into deployment via `env.valueFrom` blocks.

---

### Step 11: Persistent Storage

**Task:** Ensure MariaDB data is preserved across restarts.

**Solution:**

- Created a PersistentVolumeClaim:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

- Modified MariaDB deployment to add:

```yaml
volumeMounts:
  - mountPath: /var/lib/mysql
    name: mariadb-storage

volumes:
  - name: mariadb-storage
    persistentVolumeClaim:
      claimName: mariadb-pvc
```

- Now data in `/var/lib/mysql` persists across pod restarts.

---

## 🧠 Lessons Learned & Decisions Made

- Chose `php:7.4-apache` for compatibility
- Used Docker Hub for simplicity
- Used Secrets for sensitive data, ConfigMaps for flags
- Probes greatly improved reliability
- HPA showed strong auto-scaling under simulated load
- Rollbacks were vital for rapid recovery

---

## 📚 Conclusion

This project demonstrated how to:

- Containerize and deploy a PHP app and MariaDB
- Secure and externalize configuration
- Scale and auto-heal Kubernetes workloads
- Perform rolling updates and rollbacks with zero downtime

---

## ✅ Next Steps

- Secure app with HTTPS via Ingress + cert-manager
- Add monitoring (Prometheus + Grafana)

