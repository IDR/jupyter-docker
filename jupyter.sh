# Create ./notebooks with chmod o+wt 
exec docker run --name ome-jupyter -d -p 8888:8888 -v "/data/notebooks:/notebooks" ome-jupyter
