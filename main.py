import API
# noinspection PyPackageRequirements
import uvicorn
app = API.app
if __name__ == '__main__':
    uvicorn.run("main:app", reload=True)
