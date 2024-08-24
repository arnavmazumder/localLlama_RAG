from flask import Flask, request, Response
import ollama
import os
from utils import get_file_type, read_docx, read_text_or_code, read_pdf
import faiss
import copy
import numpy as np
import tqdm

app = Flask(__name__)

MODEL = 'llama3.1:8b'
EMBEDDER = 'nomic-embed-text:latest'
UPLOAD_FOLDER = 'uploads'
CHUNK_SIZE = 250 #chars
OVERLAP = 75 # chars
EMBED_DIMENSION = 768
K=1

index = None
text_chunks = None



@app.route('/api/llm', methods=['POST'])
def llm():
    global text_chunks
    global index

    # Sanitization
    req = request.get_json()
    if not isinstance(req, dict):
        return {'msg': 'Invalid Json.'}, 400
    if 'msgs' not in req:
        return {'msg': 'Missing msgs attribute.'}, 400
    if not isinstance(req['msgs'], list):
        return {'msg': 'Not a list of messages.'}, 400
    if not all(isinstance(msg, str) for msg in req['msgs']):
        return {'msg': 'msg values is not of type string.'}, 400
    

    # RAG

    isUser=True
    chatHistory = ''
    for i in range(len(req['msgs'])-1, -1, -1):
        if isUser:
            chatHistory += 'User: ' + req['msgs'][i] + '\n'
            isUser = False
        else:
            chatHistory += 'Bot: ' + req['msgs'][i] + '\n'
            isUser = True
    chatHistory += 'Bot: \n\n\n'
    

    if len(text_chunks)>0:
        prompt = '''
    You are a RAG bot who is conversing with a User. You will be provided with the most recent messages that you have 
    exchanged with the User as context and some relevent document information. Solely based on the context and document 
    information provided, generate your response.\n\n\n

    Context:\n\n'''
        prompt += chatHistory
        prompt += 'Document Information:\n\n'


        query_embedding = ollama.embeddings(model=EMBEDDER, prompt=req['msgs'][0])['embedding']
        _, indices = index.search(np.array([query_embedding]).astype('float32'), K)
        
        docs = ''
        for i, doc in enumerate(indices):
            for j in doc:
                docs += f'{text_chunks[i][j]}\n'

        prompt += docs
        
    else:
        prompt = '''
    You are a bot who is conversing with a User. You will be provided with the most recent messages that you have 
    exchanged with the User as context. Solely based on the context, generate your response.\n\n\n

    Context:\n\n'''
        prompt += chatHistory

    prompt+='\n\nYour output should only be your last response.'

    def stream():
        response = ollama.generate(
            model=MODEL,
            prompt=prompt,
            stream=True
        )

        for chunk in response:
            yield chunk['response']

    return Response(stream(), content_type='text/plain'), 200




@app.route('/api/updateVstore', methods=['POST'])
def updateVstore():
    global index
    global text_chunks

    # sanitization
    if 'file' not in request.files:
        return {'msg': "No file part"}, 400

    file = request.files['file']
    if file.filename == '':
        return {'msg': "No selected file"}, 400
    
    print('Pulling:', file.filename)

    # Extract Text
    filePath = os.path.join(UPLOAD_FOLDER, file.filename)
    if file:
        file.save(filePath)
    
    print('Extracting Text...')

    fileType = get_file_type(filePath)
    text = ''
    if fileType=='application/pdf': #pdf
        text = read_pdf(filePath)
    elif fileType[:4]=='text': #text or code
        text = read_text_or_code(filePath)
    elif fileType=='application/vnd.openxmlformats-officedocument.wordprocessingml.document': #docx
        text = read_docx(filePath)
    else:
        os.remove(filePath)
        return {'msg': "Bad file type"}, 400


    # Update VectorStore

    print('Chunking...')
    chunks = []
    for i in range(0, len(text), CHUNK_SIZE-OVERLAP):
        chunks.append(copy.copy(text[i:i + CHUNK_SIZE]))
        if i + CHUNK_SIZE > len(text):
            break

    print('Updating Vectorstore...')
    text_chunks.append(copy.copy(chunks))

    print('# of chunks:', len(chunks))
    embeddings = []
    for i, chunk in enumerate(tqdm.tqdm(chunks)):
        embeddings.append(ollama.embeddings(model=EMBEDDER, prompt=chunk)['embedding'])
    
    embeddings = np.array(embeddings).astype('float32')
    index.add(embeddings)

    print('Done.')
    return {'msg': 'success'}, 200



@app.route('/api/clearVstore', methods=['POST'])
def clearVstore():
    global index
    global text_chunks

    # Clear text data and index
    text_chunks = []
    index = faiss.IndexFlatL2(EMBED_DIMENSION)

    # Clear uploads folder
    files = os.listdir(UPLOAD_FOLDER)
    for file in files:
        file_path = os.path.join(UPLOAD_FOLDER, file)
        os.remove(file_path)

    return {'msg': 'success'}, 200



if __name__== '__main__':
    app.run(host='0.0.0.0', port=3000, debug=False)

    