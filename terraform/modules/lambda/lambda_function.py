import os
import boto3

def lambda_handler(event, context):
    ecr = boto3.client('ecr')

    # Mapa de alias → URL de repositorio (pasadas por vars de entorno)
    repos = {
        'vote':   os.environ['REPO_VOTE'],
        'result': os.environ['REPO_RESULT'],
        'worker': os.environ['REPO_WORKER'],
    }

    counts = {}
    for alias, url in repos.items():
        # Extrae el nombre del repo de la URL (p.ej. "voting_vote")
        repo_name = url.split('/', 1)[-1]

        # Pagina para listar todas las imágenes
        paginator = ecr.get_paginator('list_images')
        total = 0
        for page in paginator.paginate(repositoryName=repo_name):
            total += len(page.get('imageIds', []))

        counts[alias] = total

    return {
        'statusCode': 200,
        'body': counts
    }
