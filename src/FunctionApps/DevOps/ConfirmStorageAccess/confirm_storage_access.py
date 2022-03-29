from azure.storage.blob import ContainerClient
from azure.identity import DefaultAzureCredential
import azure.functions as func
import os


def main(req: func.HttpRequest) -> func.HttpResponse:

    container = req.params.get("container")

    if container:
        creds = DefaultAzureCredential()

        storage_account = os.getenv("DATA_STORAGE_ACCOUNT")
        storage_url = f"https://{storage_account}.blob.core.windows.net"
        container_service_client = ContainerClient.from_container_url(
            container_url=f"{storage_url}/{container}",
            credential=creds,
        )

        try:
            # Read root of container to validate access
            list(container_service_client.walk_blobs(delimiter="/"))
            access = 1
        except Exception:
            access = 0

        return func.HttpResponse(
            body=f'{{"access":{access}}}',
            status_code=200,
            headers={"Content-Type": "application/json"},
        )
    else:
        return func.HttpResponse(
            body='{"error":"Please pass a container name on the query string"}',
            status_code=400,
        )
