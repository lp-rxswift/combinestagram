import UIKit
import RxSwift
import RxRelay

class MainViewController: UIViewController {

  @IBOutlet weak var imagePreview: UIImageView!
  @IBOutlet weak var buttonClear: UIButton!
  @IBOutlet weak var buttonSave: UIButton!
  @IBOutlet weak var itemAdd: UIBarButtonItem!

  private let disposeBag = DisposeBag()
  private let images = BehaviorRelay<[UIImage]>(value: [])
  private let alert = PublishRelay<(String, String?)>()
  private var imageCache = [Int]()

  override func viewDidLoad() {
    super.viewDidLoad()
    images
      .subscribe(onNext: { [weak imagePreview] photos in
        guard let preview = imagePreview else { return }
        preview.image = photos.collage(size: preview.frame.size)})
      .disposed(by: disposeBag)

    images
      .subscribe(onNext: { [weak self] photos in
        self?.updateUI(photos: photos)
      })
      .disposed(by: disposeBag)

    alert
      .subscribe(onNext: { [weak self] alert in
        self?.showMessage(alert)
      })
      .disposed(by: disposeBag)
  }
  
  @IBAction func actionClear() {
    images.accept([])
    imageCache = []
  }

  @IBAction func actionSave() {
    guard let image = imagePreview.image else { return }
    PhotoWriter.save(image)
      .subscribe(onSuccess: { [weak self] id in
        self?.alert.accept((id, nil))
        self?.actionClear()
      }, onError: { [weak self] error in
        self?.alert.accept((error.localizedDescription, nil))
      })
      .disposed(by: disposeBag)
  }

  @IBAction func actionAdd() {
    let photosViewController = storyboard!
      .instantiateViewController(identifier: "PhotosViewController") as! PhotosViewController
    let newPhotos = photosViewController.selectedPhotos.share()
    newPhotos
      .filter { newImage in
        return newImage.size.width > newImage.size.height }
      .filter { [weak self] newImage in
        let len = newImage.pngData()?.count ?? 0
        guard self?.imageCache.contains(len) == false else {
          return false
        }
        self?.imageCache.append(len)
        return true
      }
      .subscribe(onNext: { [weak self] newImage in
        guard let images  = self?.images else { return }
        images.accept(images.value + [newImage])
      }, onDisposed: {
        print("Completed photo selection")
      }).disposed(by: disposeBag)
    navigationController!.pushViewController(photosViewController, animated: true)

    newPhotos
      .ignoreElements()
      .subscribe(onCompleted: { [weak self] in
        self?.updateNavigationIcon()
      })
      .disposed(by: disposeBag)
  }

  func showMessage(_ message: (String, String?)) {
    DispatchQueue.main.async { [weak self] in
      let alert = UIAlertController(title: message.0, message: message.1, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { [weak self] _ in self?.dismiss(animated: true, completion: nil)}))
      self?.present(alert, animated: true, completion: nil)
    }
  }

  private func updateNavigationIcon() {
    let icon = imagePreview.image?
      .scaled(CGSize(width: 22, height: 22))
      .withRenderingMode(.alwaysOriginal)

    navigationItem.leftBarButtonItem = UIBarButtonItem(
      image: icon, style: .done,
      target: nil, action: nil)
  }

  private func updateUI(photos: [UIImage]) {
    buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
    buttonClear.isEnabled = photos.count > 0
    itemAdd.isEnabled = photos.count < 6
    title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
  }
}
