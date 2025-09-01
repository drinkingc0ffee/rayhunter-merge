import osmnx as ox

# Define the place name
place = "South Orange, New Jersey, USA"

# Download the boundary polygon as a GeoDataFrame
gdf = ox.geocode_to_gdf(place)

# Save to GeoJSON
gdf.to_file("south_orange_boundary.geojson", driver="GeoJSON")

print("GeoJSON file saved as south_orange_boundary.geojson")
