#exec docker run --rm -it -p 8888:8888 -v "$(pwd):/notebooks" jupyter/notebook "jupyter" "notebook" "--no-browser"
# Create ./notebooks with chmod o+wt 
exec docker run --rm -it -p 9999:8888 -v "`pwd`/tmp:/notebooks" ome-jupyter
