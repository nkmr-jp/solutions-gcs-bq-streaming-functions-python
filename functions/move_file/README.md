# ローカルでテストする方法 (WIP)

See: https://cloud.google.com/functions/docs/running/function-frameworks

## 環境構築

```sh
pyenv install 3.7.13
python -m venv venv
./venv/bin/pip install functions-framework 
./venv/bin/pip install -r requirements.txt  
```

```sh
./venv/bin/functions_framework --target=move_file --signature-type=cloudevent  
```
