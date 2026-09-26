resource "kubernetes_namespace_v1" "tech_store" {
  count = var.manage_namespace_with_terraform ? 1 : 0
  metadata {
    name = "tech-store"
    labels = { "app.kubernetes.io/part-of" = "tech-store" }
  }
  depends_on = [module.eks]
}
