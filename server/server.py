from flask import Flask, request, Response
import ollama

app = Flask(__name__)

MODEL = 'llama3.1:8b'


@app.route('/api/llm', methods=['POST'])
def llm():

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

    prompt = '''
        Pretend you are a chatbot named Friday who is currently engaging with your creator. You will be provided with
        the most recent few messages that you have exchanged with them as context. Solely based on
        the context provided, generate your next response. If you address your creator in your response, please ensure that you refer to them as 'sir'.\n\n\n

        Context:\n\n
    '''

    isUser=True
    for i in range(len(req['msgs'])-1, -1, -1):
        if isUser:
            prompt += 'Creator: ' + req['msgs'][i] + '\n'
            isUser = False
        else:
            prompt += 'Friday: ' + req['msgs'][i] + '\n'
            isUser = True
    prompt += 'Friday: '



    def stream():
        response = ollama.chat(
            model=MODEL,
            messages=[
                {
                    "role": "user",
                    "content": prompt,
                },
            ],
            stream=True
        )

        for chunk in response:
            yield chunk['message']['content']
    


    return Response(stream(), content_type='text/plain'), 200






if __name__== '__main__':
    app.run(host='0.0.0.0', port=3000, debug=False)

    