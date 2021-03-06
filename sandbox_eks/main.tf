
provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "aws_eks_cluster" "elliotteks" {
  name     = "elliotteks"
  role_arn = aws_iam_role.eks-iam-role.arn

  vpc_config {
    subnet_ids = [for id in var.public_eks_subnets: id.id]
  }

  depends_on = [
  aws_iam_role.eks-iam-role,
 ]
}


resource "aws_iam_role" "eks-iam-role" {
  name = "eks-cluster-"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
 policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
 role    = aws_iam_role.eks-iam-role.name
}
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly-EKS" {
 policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
 role    = aws_iam_role.eks-iam-role.name
}


resource "aws_iam_role" "workernodes" {
  name = "eks-node-group"
 
  assume_role_policy = jsonencode({
   Statement = [{
    Action = "sts:AssumeRole"
    Effect = "Allow"
    Principal = {
     Service = "ec2.amazonaws.com"
    }
   }]
   Version = "2012-10-17"
  })
 }
 
 resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role    = aws_iam_role.workernodes.name
 }
 
 resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role    = aws_iam_role.workernodes.name
 }
 
 resource "aws_iam_role_policy_attachment" "EC2InstanceProfileForImageBuilderECRContainerBuilds" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  role    = aws_iam_role.workernodes.name
 }
 
 resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role    = aws_iam_role.workernodes.name
 }

  resource "aws_eks_node_group" "worker-node-group" {
  cluster_name  = aws_eks_cluster.elliotteks.name
  node_group_name = "elliotts-eks-workernodes"
  node_role_arn  = aws_iam_role.workernodes.arn
  subnet_ids   = [for id in var.private_eks_subnets: id.id]
  instance_types = ["t3.xlarge"]
 
  scaling_config {
   desired_size = 1
   max_size   = 1
   min_size   = 1
  }
 
  depends_on = [
   aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
   aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
  ]
 }



#SERVICE ACCOUNT CONFIG 

data "tls_certificate" "ekstls" {
  url = aws_eks_cluster.elliotteks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eksoidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.ekstls.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.elliotteks.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "eksdoc_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eksoidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eksoidc.arn]
      type        = "Federated"
    }
  }
}



# elliotteks
# terraform apply --auto-approve 
# helm repo add bitnami https://charts.bitnami.com/bitnami
# aws eks update-kubeconfig --name elliotteks --region us-west-2
# kubectl create ns metrics
# helm install kube-state-metrics bitnami/kube-state-metrics -n metrics 
# helm ls -n metrics
# kubectl get all -n metrics
# kubectl logs pod/kube-state-metrics-bdbf7ddd7-djljd    -n metrics
# kubectl port-forward svc/kube-state-metrics -n metrics  8080:8080
# helm show chart bitnami/kube-state-metrics
# helm show values bitnami/kube-state-metrics > values.yaml && code values.yaml
# helm ls -n metrics 
# helm upgrade kube-state-metrics bitnami/kube-state-metrics --version 3.0.5  -n metrics
# helm install first-chart .
# helm template first-chart .
# helm upgrade first-chart .
# kubectl describe cm  first-chart-configmap  - after creating a config map 
# echo -n 'username' | base64
# echo -n 'password' | base64     - creating secret
# helm template first-chart .  - see the new secret before deploying changes to cluster 
# helm upgrade first-chart .
# kubectl describe secret first-secret
# helm history first-chart
# helm rollback first-chart 1
#helm rollback first-chart
#use templating language to update values  first-configmap-{{.Chart.Version}}
