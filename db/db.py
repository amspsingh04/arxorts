import firebase_admin
from firebase_admin import credentials, firestore
import requests
import xmltodict  

cred = credentials.Certificate(r"C:\\Users\\spsin\\Downloads\\arxorts-firebase-adminsdk-fbsvc-7b90773ccd.json")  # Keep raw string format for Windows paths
firebase_admin.initialize_app(cred)
db = firestore.client()

search_terms = ["AI", "ML", "CNN", "LLM", "NLP", "CV"]

def fetch_and_store_arxiv_articles():
    for tag in search_terms:
        url = f"http://export.arxiv.org/api/query?search_query=all:{tag}&sortBy=submittedDate&sortOrder=descending&max_results=2000"
        try:
            response = requests.get(url)
            if response.status_code == 200:
                data = xmltodict.parse(response.text)  
                
                articles = data['feed']['entry']
                if not isinstance(articles, list):  
                    articles = [articles]

                for article in articles:
                    title = article['title'].strip()
                    abstract = article['summary'].strip()
                    
                    pdf_url = ""
                    if isinstance(article["link"], list):  
                        for link in article["link"]:
                            if "@title" in link and link["@title"] == "pdf":
                                pdf_url = link["@href"]
                                break
                    elif isinstance(article["link"], dict) and "@title" in article["link"]:
                        pdf_url = article["link"]["@href"]

                    db.collection("articles").add({
                        "title": title,
                        "abstract": abstract,
                        "pdfUrl": pdf_url,
                        "timestamp": firestore.SERVER_TIMESTAMP,
                        "tag": tag  
                    })

                print(f"✅ Articles for {tag} successfully stored in Firestore.")
            else:
                print(f"❌ Failed to fetch articles for {tag}. Status code: {response.status_code}")
        except Exception as e:
            print(f"⚠️ Error fetching articles for {tag}: {e}")

fetch_and_store_arxiv_articles()
