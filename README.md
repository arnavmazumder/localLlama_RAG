# Local Llama RAG

This iOS/macOS application is a locally powered Llama 3.1 (8b) chatbot with retrieval augmented generation (RAG) capabilities, using a local FAISS vectorstore. 

![hippo](https://i.giphy.com/media/v1.Y2lkPTc5MGI3NjExZ2Nid2x4MWdrYWpvNWEzbGlrZXRheGU4cTUzejBmOWR6Z2k1cjBlaCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/zvMGOv6wC1viQa6N9U/giphy.gif)


## Technologies Used

- **Frontend**: Dart, http, Swift, Ruby, Objective C
- **Backend**: Python, Flask, ollama, faiss, numPy
- **Development Tools**: VSCode, GitHub, Flutter

## Getting Started
This repository contains all of the code necessary for running the application locally in debug mode.

### Prereqs
- macOS
- VS Code
- Python: &nbsp;&nbsp;<a href=https://www.python.org/downloads>View instructions here.</a>
- Flutter: &nbsp;&nbsp;<a href=https://docs.flutter.dev/get-started/install/macos>View instructions here.</a>


**Clone the repository and enter the main directory:**
   ```bash
   git clone https://github.com/arnavmazumder/localLlama_RAG.git
   cd localLlama_RAG
   ```

**Enter the server directory and install python dependencies:**
```bash
cd server
pip install -r dependencies.txt
```

**You will also need to install FAISS:**
For CPU:
```bash
pip install faiss-cpu
```

For GPU:
```bash
pip install faiss-gpu
```

**Enter the client directory and ensure that Flutter, Xcode, VS Code, Connected device, and Network resources are operating as expected:**
```bash
cd ../client
flutter doctor
```


### Running Locally

1. **Start Flutter in the client directory**
In a new terminal window, run the following commands:
   ```bash
   cd localLlama_RAG/client
   flutter run
   ```

   Follow the instructions to start the application on macOS or iOS (for iOS, you must begin the iOS simulator).

   <br>

2. **Run Flask Server**
In a new terminal window, run the following commands:
    ```bash
    cd localLlama_RAG/server
    python3 server.py
    ```

    From this window, you will be able to view incoming requests and processing details for retrieved documents.
    <br>
 

### Usage

First, select a directory that contains all documents that you would like to be scanned for retrieval. This scan is not recursive. If you do not wish to utilize RAG during your conversation with the chatbot, select a directory that is empty or that only contains directories. Once you have selected a directory, you may converse with the chatbot using the provided text bar.


If you ran into any issues or have any questions, you can contact me at arnavmazumder2023@gmail.com.










