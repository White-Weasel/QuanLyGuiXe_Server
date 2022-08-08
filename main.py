import ParkingServer
# noinspection PyPackageRequirements
import uvicorn
app = ParkingServer.app
if __name__ == '__main__':
    uvicorn.run("main:app", reload=True)
