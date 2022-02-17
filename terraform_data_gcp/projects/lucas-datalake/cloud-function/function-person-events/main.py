#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Dec 17 10:23:03 2020

@author: lucas.mari
"""
import random
import threading
import logging
import uuid
import pandas as pd
import datetime
from hashlib import sha256
from faker import Faker
import time
import json
import os
from packages.pub_sub import PubSub

def execute(request):
    i = 0
    project = os.environ.get("PROJECT_ID",'lucas-datalake-dev')
    TOPIC = os.environ.get("TOPIC",'lucas-person-events')
    while i<=1000:
        try:    
            dfProdutos = pd.read_csv('produtos.csv', sep=';')
            idRandomCompra = sha256((str(uuid.uuid4()) + 
                                    datetime.datetime.now().strftime('%Y-%m-%d %H:%m:%s')
                                    ).encode('utf-8')).hexdigest()
            fake = Faker('pt_BR')
            person = fake.profile()
            start_date = datetime.date(year=2019, month=1, day=1)
            seriesProdutos = dfProdutos.sample(n=1)
            pub_sub = PubSub(PROJECT_ID=project)
            person = {"nome": person['name'],
                    "dtNascimento": person['birthdate'].strftime('%Y-%m-%d'),
                    "empresa": person['company'],
                    "profissao": person['job'],
                    "cpf": person['ssn'],
                    "enderecoCompleto": person['residence'].replace('\n',' '),
                    "logradouro": person['residence'].split('\n')[0],
                    "bairro": person['residence'].split('\n')[1],
                    "cep": person['residence'].split('\n')[2][:8],
                    "cidade": person['residence'].split('\n')[2][9:].split('/')[0].strip(),
                    "estado": person['residence'].split('\n')[2][9:].split('/')[1].strip(),
                    "idCompra": str(idRandomCompra),
                    "idProduto": int(seriesProdutos['id'].values[0]),
                    "produtoDescricao": seriesProdutos['produto'].values[0],
                    "qtCompra": int(random.choice(range(1,6))),
                    "dtCompra": fake.date_between(start_date=start_date, 
                                                    end_date = datetime.datetime.now()
                                                    ).strftime('%Y-%m-%d %H:%M:%S'),
                    "precoUnitario": round(seriesProdutos['precoUnit'].values[0],2)/10,
                    "pais": "Brasil"
                    }
            pub_sub.publish_message_datalake(topic_name=TOPIC, 
                                        message=person
                                        )   
        except Exception as ex:
            print(ex)
