# Create ./notebooks with chmod o+wt 
exec docker run --rm -it -p 8888:8888 -v "/data/notebooks:/notebooks" ome-jupyter
