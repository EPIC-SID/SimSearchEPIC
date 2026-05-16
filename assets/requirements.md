we need speed more important

we take images give it to open ai model (clip)
then model gives output embedded vector 512 vala
vector store in 2 location 1 in sql and other faiss (facebook ai similarity search)

we give prompt "beach photoss" then it goes to open ai model then it converts text to embedding then we convert that to similar embeddings and create a list humare pass ek embedding ki list agayi
unn embedding ke list ko sql se nikalege toh hume path ki list milegi voh list frontend ko jaegi aur vaha se display hogi desired images

hum open source model iuse krre taki locally hojaye
hum image process krnev ale hai toh voh one time processing hai
user se input lo uski embedding nikalke usse similar embeds dhundo

face recognition bhi chiye
for that face mein dusra table banega like face and uska instance rhega (doubtfull part)
