import os
import subprocess
import datetime
import json

def generate_kubeconfig():
    endpoint = os.environ["CLUSTER_ENDPOINT"]
    ca_data = os.environ["CLUSTER_CA"]
    token = os.environ["EKS_TOKEN"]

    kubeconfig = {
        "apiVersion": "v1",
        "kind": "Config",
        "clusters": [{
            "name": "k8s",
            "cluster": {
                "server": endpoint,
                "certificate-authority-data": ca_data
            }
        }],
        "contexts": [{
            "name": "aws",
            "context": {
                "cluster": "k8s",
                "user": "aws"
            }
        }],
        "current-context": "aws",
        "users": [{
            "name": "aws",
            "user": {
                "token": token
            }
        }]
    }

    os.makedirs("/tmp/.kube", exist_ok=True)
    config_path = "/tmp/.kube/config"

    with open(config_path, "w") as f:
        json.dump(kubeconfig, f)

    os.environ["KUBECONFIG"] = config_path

def lambda_handler(event, context):
    region       = os.environ["REGION"]
    cluster_name = os.environ["CLUSTER_NAME"]
    bucket_name  = os.environ["BUCKET_NAME"]
    environment  = os.environ.get("ENV", "default")

    timestamp = datetime.datetime.utcnow().strftime("%Y%m%d-%H%M%S")
    backup_file = f"/tmp/eks-backup-{timestamp}.yaml"
    kubectl_path = os.path.join(os.getcwd(), "bin", "kubectl")

    try:
        print("🔧 Generando kubeconfig...")
        generate_kubeconfig()

        print("📦 Ejecutando kubectl backup...")
        with open(backup_file, "w") as f:
            subprocess.run(
                [kubectl_path, "get", "all", "--all-namespaces", "-o", "yaml"],
                stdout=f,
                stderr=subprocess.PIPE,
                check=True
            )

        print("⬆️ Subiendo backup a S3...")
        import boto3
        s3 = boto3.client("s3", region_name=region)
        s3.upload_file(backup_file, bucket_name, f"{environment}/eks-backup-{timestamp}.yaml")

        print("✅ Backup completado exitosamente.")
        return {"status": "success", "file": backup_file}

    except subprocess.CalledProcessError as e:
        print(f"❌ Error ejecutando kubectl: {e.stderr.decode()}")
        raise

    except Exception as e:
        print(f"❌ Error general: {e}")
        raise