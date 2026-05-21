the index.py looks at the folder images/ and test_media/ and extracts image embeddings save it to faiss db and then the faiss returns a token id which corresponds to the image path which is stored in the sqldb

if any issue occurs run: 
python clear_db.py
and then run index.py

search.py gives top 20% similar images
may return garbage sometimes cause it always gibes top 20 even if the confidence is low

it prints the json which has path to the image and its score which should be passed to the ui and it will display it