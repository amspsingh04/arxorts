import firebase_admin
from firebase_admin import credentials, firestore
import requests
import xmltodict  # Correct library for XML parsing

# Initialize Firebase
cred = credentials.Certificate(r"C:\\Users\\spsin\\Downloads\\arxorts-firebase-adminsdk-fbsvc-7b90773ccd.json")  # Keep raw string format for Windows paths
firebase_admin.initialize_app(cred)
db = firestore.client()

def fetch_and_store_arxiv_articles():
    url = "http://export.arxiv.org/api/query?search_query=all:AI&sortBy=submittedDate&sortOrder=descending&max_results=1000"
    
    try:
        response = requests.get(url)
        if response.status_code == 200:
            data = xmltodict.parse(response.text)  # Convert XML to Python dict
            
            articles = data['feed']['entry']
            if not isinstance(articles, list):  # Handle single entry case
                articles = [articles]

            for article in articles:
                title = article['title'].strip()
                abstract = article['summary'].strip()
                
                # Extract PDF link correctly
                pdf_url = ""
                if isinstance(article["link"], list):  # Handle multiple link tags
                    for link in article["link"]:
                        if "@title" in link and link["@title"] == "pdf":
                            pdf_url = link["@href"]
                            break
                elif isinstance(article["link"], dict) and "@title" in article["link"]:
                    pdf_url = article["link"]["@href"]

                # Store in Firestore (Use a shorter unique identifier for the document name)
                db.collection("articles").add({
                    "title": title,
                    "abstract": abstract,
                    "pdfUrl": pdf_url,
                    "timestamp": firestore.SERVER_TIMESTAMP
                })

            print("✅ Articles successfully stored in Firestore.")
        else:
            print(f"❌ Failed to fetch articles. Status code: {response.status_code}")
    except Exception as e:
        print(f"⚠️ Error fetching articles: {e}")

# Run function
fetch_and_store_arxiv_articles()
