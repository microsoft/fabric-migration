from datetime import datetime
import json
import os
import requests
import base64

from notebookutils import mssparkutils

class Utils:

    # Synapse utils

    def get_access_token(azure_client_id, azure_tenant_id, azure_client_secret):
        url = f"https://login.microsoftonline.com/{azure_tenant_id}/oauth2/token"

        payload = {
            "grant_type": "client_credentials",
            "client_id": {azure_client_id},
            "client_secret": {azure_client_secret},
            "resource": f"https://dev.azuresynapse.net/"
        }

        headers = {'Content-Type': 'application/x-www-form-urlencoded'}

        response = requests.post(url, data=payload, headers=headers)
        response_json = json.loads(response.text)
        synapse_dev_token = response_json["access_token"]

        return synapse_dev_token

    # Notebook utils

    def clean_notebook_cells(ntbk_json, tags_to_clean):
        for cell in ntbk_json['cells']:
            for tag in tags_to_clean:
                if tag in cell:
                    cell[tag] = []

        return ntbk_json

    def export_notebooks(azure_client_id, azure_tenant_id, azure_client_secret, synapse_workspace_name, output_folder):
        resource_type = "notebooks"
        Utils.export_resources(resource_type, azure_client_id, azure_tenant_id, azure_client_secret, synapse_workspace_name, output_folder)

    def import_notebooks(output_folder, workspace_id, prefix):

        date = datetime.now().strftime('%Y_%m_%dT%H_%M_%S')
        resource_type = "notebooks"
        res_imported = 0
        resources_imported = {}

        artifact_path = f"{output_folder}/{resource_type}"

        if os.path.exists(artifact_path) == False:
            print(f"Path where the import artifacts from Synapse are located {artifact_path} does not exist. Exiting ...")

        print(f"Importing individual resources of type '{resource_type}' into Fabric workspace '{workspace_id}'...")
        dir_list = os.listdir(artifact_path)
        for file in dir_list:
            file_path = os.path.join(artifact_path, file)
            if(file_path.endswith(".ipynb")):
                with open(file_path, "r", encoding='utf-8') as read_file:
                    ntbk_json = json.load(read_file)
                file_name_noext = file.split('/')[-1].split('.')[0]
                ntbk_name = f"{prefix}_{file_name_noext}"
                Utils.import_notebook(ntbk_name, ntbk_json, workspace_id, False)
                res_imported += 1
                resources_imported[resource_type] = res_imported

        print(f"Finish importing {resources_imported[resource_type]} items of type: {resource_type}")
        
    def import_notebook(ntbk_name, ntbk_json, workspace_id, overwrite=False):

        api_endpoint = "api.fabric.microsoft.com"
        pbi_token = mssparkutils.credentials.getToken('https://analysis.windows.net/powerbi/api') 

        print(f"Importing '{ntbk_name}'...")
        url = f"https://{api_endpoint}/v1/workspaces/{workspace_id}/items"

        json_str = json.dumps(ntbk_json)
        json_bytes = json_str.encode('utf-8')
        base64_encoded_json = base64.b64encode(json_bytes)
        base64_str = base64_encoded_json.decode('utf-8')

        payload = json.dumps({
            "type": "Notebook",
            "description": "Imported from Synapse",
            "displayName": ntbk_name,
            "definition" : {
                "format": "ipynb",
                "parts" : [
                    {
                        "path": "notebook-content.ipynb",
                        "payload": base64_str,
                        "payloadType": "InlineBase64"
                    }
                ]
            }
        })

        headers = {
            'Authorization': f'Bearer {pbi_token}',
            'Content-Type': 'application/json'
        }

        response = requests.request("POST", url, headers=headers, data=payload)

        if response.status_code == 200:
            print(f">> Notebook '{ntbk_name}' created.")
        else:
            raise RuntimeError(f"Notebook '{ntbk_name}' creation failed: {response.status_code}: {response.text}")

    # SJD utils

    def export_sjd(azure_client_id, azure_tenant_id, azure_client_secret, synapse_workspace_name, output_folder):
        resource_type = "sparkJobDefinitions"
        Utils.export_resources(resource_type, azure_client_id, azure_tenant_id, azure_client_secret, synapse_workspace_name, output_folder)

    def import_sjd(sjd_name, sjd_json, workspace_id, overwrite=False):

        api_endpoint = "api.fabric.microsoft.com"
        pbi_token = mssparkutils.credentials.getToken('https://analysis.windows.net/powerbi/api') 

        print(f"Importing '{sjd_name}'...")
        url = f"https://{api_endpoint}/v1/workspaces/{workspace_id}/items"

        json_str = json.dumps(sjd_json)
        json_bytes = json_str.encode('utf-8')
        base64_encoded_json = base64.b64encode(json_bytes)
        base64_str = base64_encoded_json.decode('utf-8')

        payload = json.dumps({
            "type": "SparkJobDefinition",
            "description": "Imported from Synapse",
            "displayName": sjd_name,
            "definition" : {
                "format": "SparkJobDefinitionV1",
                "parts" : [
                    {
                        "path": "SparkJobDefinitionV1.json",
                        "payload": base64_str,
                        "payloadType": "InlineBase64"
                    }
                ]
            }
        })

        headers = {
            'Authorization': f'Bearer {pbi_token}',
            'Content-Type': 'application/json'
        }

        response = requests.request("POST", url, headers=headers, data=payload)

        if response.status_code == 200:
            print(f">> SJD '{sjd_name}' created.")
        else:
            raise RuntimeError(f"SJD '{sjd_name}' creation failed: {response.status_code}: {response.text}")
        
    def import_sjd_from_json(sjd_name, sjd_json, workspace_id, lakehouse_id, overwrite=False):

        executable_file_path = sjd_json["properties"]["jobProperties"]["file"]
        language = sjd_json["properties"]["language"]
        if language == "scala":
            mainclass = sjd_json["properties"]["jobProperties"]["className"]
            language = "Scala/Java"
        else:
            mainclass = None
        libs = sjd_json["properties"]["jobProperties"]["jars"]
        libs = " ".join(libs)
        args = sjd_json["properties"]["jobProperties"]["args"]
        args = " ".join(args)
        
        workload_json = {
            "executableFile":executable_file_path,
            "defaultLakehouseArtifactId":lakehouse_id,
            "mainClass":mainclass,
            "additionalLakehouseIds":[],
            "retryPolicy":None,
            "commandLineArguments":args,
            "additionalLibraryUris":libs,
            "language":language,
            "environmentArtifactId":None
        }
    
        Utils.import_sjd(sjd_name, workload_json, workspace_id, False)

    def import_sjds(output_folder, workspace_id, lakehouse_id, prefix):

        resource_type = "sparkJobDefinitions"
        res_imported = 0
        resources_imported = {}

        artifact_path = f"{output_folder}/{resource_type}"

        if os.path.exists(artifact_path) == False:
            print(f"Path where the import artifacts from Synapse are located {artifact_path} does not exist. Exiting ...")

        print(f"Importing individual resources of type '{resource_type}' into Fabric workspace '{workspace_id}'...")
        dir_list = os.listdir(artifact_path)
        for file in dir_list:
            file_path = os.path.join(artifact_path, file)
            if(file.endswith(".json")):
                with open(file_path, "r", encoding='utf-8') as read_file:
                        sjd_json = json.load(read_file)
                file_name_noext = file.split('/')[-1].split('.')[0]
                sjd_name = f"{prefix}_{file_name_noext}"
                Utils.import_sjd_from_json(sjd_name, sjd_json, workspace_id, lakehouse_id, False)
                res_imported += 1
                resources_imported[resource_type] = res_imported

        print(f"Finish importing {resources_imported[resource_type]} items of type: {resource_type}")

    # Generic

    def export_resources(resource_type, azure_client_id, azure_tenant_id, azure_client_secret, synapse_workspace_name, output_folder):

        base_uri = f"{synapse_workspace_name}.dev.azuresynapse.net"
        api_version = "2020-12-01"
        synapse_dev_token = Utils.get_access_token(azure_client_id, azure_tenant_id, azure_client_secret)
        res_exported = 0
        resources_exported = {}

        url = f"https://{base_uri}/{resource_type}?api-version={api_version}"

        headers = {
            'Authorization': f'Bearer {synapse_dev_token}',
            'Content-Type': 'application/json'
        }

        response = requests.request("GET", url, headers=headers)

        if response != None and (response.status_code == 202 or response.status_code == 200):
            response_json = response.json()
            print(f"Exporting individual resources of type '{resource_type}' from '{synapse_workspace_name}' Azure Synapse workspace...")
            if "value" in response_json:
                response_json = response_json['value']
            elif "items" in response_json:
                response_json = response_json['items']
            for artifact in response_json:
                if "name" in artifact:
                    resource_name = artifact["name"]
                elif "Name" in artifact:
                    resource_name = artifact["Name"]
                print(f"Exporting '{resource_name}' ...")
                resource_url = f"https://{base_uri}/{resource_type}/{resource_name}?api-version={api_version}"
                resource_response = requests.request("GET", resource_url, headers=headers)

                if resource_response != None and (resource_response.status_code == 202 or resource_response.status_code == 200):
                    resource_response_json = resource_response.json()

                    if (resource_type == "sparkJobDefinitions"):
                        sjd_json = resource_response_json
                        file_name = f"{resource_name}.json"
                        data = json.dumps(sjd_json, indent=4)
                    elif (resource_type == "notebooks"):
                        notebook_json = resource_response_json['properties']
                        tags_to_clean = ['outputs']
                        updated_ntbk_json = Utils.clean_notebook_cells(notebook_json, tags_to_clean)
                        file_name = f"{resource_name}.ipynb"
                        data = json.dumps(updated_ntbk_json, indent=4)
                    
                    mssparkutils.fs.put(f"{output_folder}/{resource_type}/{file_name}", data, False)
                    res_exported += 1
                    resources_exported[resource_type] = res_exported
                    
        else:
            raise RuntimeError(f"Exporting items of type '{resource_type}' failed: {response.status_code}: {response}")

        print(f"Finish exporting {resources_exported[resource_type]} items of type: {resource_type}")
    