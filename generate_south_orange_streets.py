import osmnx as ox

# Define the place name
place = "South Orange, New Jersey, USA"

# Download the street network as LineStrings
G = ox.graph_from_place(place, network_type="walk")

# Convert the graph to GeoDataFrame (edges as LineStrings)
gdf_edges = ox.graph_to_gdfs(G, nodes=False, edges=True)

# Save to GeoJSON
gdf_edges.to_file("south_orange_streets.geojson", driver="GeoJSON")

print("GeoJSON file saved as south_orange_streets.geojson")
