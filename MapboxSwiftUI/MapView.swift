//
//  MapView.swift
//  iosApp
//
//  Created by KerwinHong on 2023/2/14.
//  Copyright © 2023 orgName. All rights reserved.
//

import SwiftUI
import MapboxCoreNavigation
import MapboxNavigation
import MapboxMaps


struct MapViewSwift: UIViewControllerRepresentable {
    
    @State var showCurrentLocation = true
    
    func makeUIViewController(context: Context) -> some MapboxController {
        return MapboxController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        uiViewController.showCurrentLocation = showCurrentLocation
    }
    
    
}

struct MapViewSwift_Previews: PreviewProvider {
    static var previews: some View {
        MapViewSwift().ignoresSafeArea()
    }
}


class MapboxController: UIViewController {
    
    private enum Constants {
        static let ICON_KEY = "icon_key"
        static let BLUE_MARKER_PROPERTY = "icon_blue_property"
        static let RED_MARKER_PROPERTY = "icon_red_property"
        static let BLUE_ICON_ID = "blue"
        static let RED_ICON_ID = "red"
        static let SOURCE_ID = "source_id"
        static let LAYER_ID = "layer_id"
    }
    
    var zoom: CGFloat? = 8
    var showCurrentLocation: Bool = true {
        didSet {
            if showCurrentLocation {
                mapView.location.delegate = self
                mapView.location.options.puckType = .puck2D()
            } else {
                mapView.location.delegate = nil
                mapView.location.options.puckType = nil
            }
        }
    }
    
    private var mapView: MapView!
    private var cameraLocationConsumer: CameraLocationConsumer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let centerCoordinate = CLLocationCoordinate2D(latitude: 55.70651, longitude: 12.554729)
        let options = MapInitOptions(cameraOptions: CameraOptions(center: centerCoordinate, zoom: 8))
        
        mapView = MapView(frame: view.bounds, mapInitOptions: options)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.gestures.delegate = self
        view.addSubview(mapView)
        
        cameraLocationConsumer = CameraLocationConsumer(mapView: mapView, zoom: zoom)
        
        mapView.mapboxMap.onNext(event: .mapLoaded) { [self] _ in
            self.prepareStyle()
            if showCurrentLocation {
                self.mapView.location.addLocationConsumer(newConsumer: self.cameraLocationConsumer)
            }
            
            // The following line is just for testing purposes.
            //            self.finish()
        }
        
        mapView.mapboxMap.style.uri = .streets
        
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        mapView.frame = view.bounds
    }
    
    
    func requestPermissionsButtonTapped() {
        mapView.location.requestTemporaryFullAccuracyPermissions(withPurposeKey: "PilotMapBox")
    }
    
    
    
    // MARK: - Style management
    
    private func prepareStyle() {
        let style = mapView.mapboxMap.style
        try? style.addImage(UIImage(named: "blue_marker_view")!, id: Constants.BLUE_ICON_ID)
        try? style.addImage(UIImage(named: "red_marker")!, id: Constants.RED_ICON_ID)
        
        var features = [Feature]()
        var feature = Feature(geometry: Point(LocationCoordinate2D(latitude: 55.608166, longitude: 12.65147)))
        feature.properties = [Constants.ICON_KEY: .string(Constants.BLUE_MARKER_PROPERTY)]
        features.append(feature)
        
        var feature1 = Feature(geometry: Point(LocationCoordinate2D(latitude: 55.70651, longitude: 12.554729)))
        feature1.properties = [Constants.ICON_KEY: .string(Constants.RED_MARKER_PROPERTY)]
        features.append(feature1)
        
        var source = GeoJSONSource()
        source.data = .featureCollection(FeatureCollection(features: features))
        try? style.addSource(source, id: Constants.SOURCE_ID)
        
        let rotateExpression = Exp(.match) {
            Exp(.get) { Constants.ICON_KEY }
            Constants.BLUE_MARKER_PROPERTY
            45
            0
        }
        let imageExpression = Exp(.match) {
            Exp(.get) { Constants.ICON_KEY }
            Constants.BLUE_MARKER_PROPERTY
            Constants.BLUE_ICON_ID
            Constants.RED_MARKER_PROPERTY
            Constants.RED_ICON_ID
            Constants.RED_ICON_ID
        }
        var layer = SymbolLayer(id: Constants.LAYER_ID)
        layer.source = Constants.SOURCE_ID
        layer.iconImage = .expression(imageExpression)
        layer.iconAnchor = .constant(.bottom)
        layer.iconAllowOverlap = .constant(false)
        layer.iconRotate = .expression(rotateExpression)
        try? style.addLayer(layer)
    }
    
    
}

extension MapboxController: LocationPermissionsDelegate {
    func locationManager(_ locationManager: LocationManager, didChangeAccuracyAuthorization accuracyAuthorization: CLAccuracyAuthorization) {
        if accuracyAuthorization == .reducedAccuracy {
            // Perform an action in response to the new change in accuracy
        }
    }
}

extension MapboxController: GestureManagerDelegate {
    func gestureManager(_ gestureManager: MapboxMaps.GestureManager, didBegin gestureType: MapboxMaps.GestureType) {
        
    }
    
    func gestureManager(_ gestureManager: MapboxMaps.GestureManager, didEnd gestureType: MapboxMaps.GestureType, willAnimate: Bool) {
        
    }
    
    func gestureManager(_ gestureManager: MapboxMaps.GestureManager, didEndAnimatingFor gestureType: MapboxMaps.GestureType) {
        
    }
    
    
}


public class CameraLocationConsumer: LocationConsumer {
    weak var mapView: MapView?
    var zoom: CGFloat? = 8
    
    init(mapView: MapView, zoom: CGFloat?) {
        self.mapView = mapView
        self.zoom = zoom
    }
    
    public func locationUpdate(newLocation: Location) {
        mapView?.camera.ease(
            to: CameraOptions(center: newLocation.coordinate, zoom: self.zoom),
            duration: 0)
    }
}
