//
//  ZomVerificationDetailViewController.swift
//  Zom
//
//  Created by Benjamin Erhart on 06.03.18.
//

/**
 Scene for verification of all fingerprints of a buddy.

 Use the `convenience init(buddy: OTRBuddy)` or set `self.buddy` immediately after init!

 Better, yet, if you already loaded keys/fingerprints, use the
 `convenience init(buddy: OTRBuddy?, omemoDevices: [OMEMODevice]?, otrFingerprints: [OTRFingerprint]?)`.

*/
class ZomVerificationDetailViewController: ZomFingerprintBaseViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var subtitleLb: UILabel!
    @IBOutlet weak var descriptionLb: UILabel!
    @IBOutlet weak var fingerprintTable: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let titleView = navigationItem.titleView as? OTRTitleSubtitleView {
            titleView.titleLabel.text = NSLocalizedString("Zom Codes", comment:
                "Title for code verification detail scene")
        }

        descriptionLb.text = NSLocalizedString("Make sure the codes match your friend's latest Zom codes on his or her phone.",
                                               comment: "Description for code verification detail scene")

        fingerprintTable.register(UINib(nibName: "ZomFingerprintVerificationCell", bundle: nil),
                                  forCellReuseIdentifier: "FingerprintCell")
        fingerprintTable.register(UINib(nibName: "ZomFingerprintVerificationHeader", bundle: nil),
                                  forCellReuseIdentifier: "FingerprintHeader")
        fingerprintTable.tableFooterView = UIView(frame: .zero)
    }

    /**
     Callback, when all OMEMO devices and all OTR fingerprints of our buddy are loaded.

     Update the number of untrusted new fingerprints text and reload the table to show all
     fingerprints.
    */
    override func fingerprintsLoaded() {
        updateUntrustedNewFingerprintsInfo()

        fingerprintTable.reloadData()
    }

    // MARK: ZomFingerprintVerificationCell

    /**
     Callback for `ZomFingerprintVerificationCell`, when a user changed the trust of a fingerprint.
    */
    func trustChanged() {
        updateUntrustedNewFingerprintsInfo()
    }

    // MARK: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        var count = 0

        if omemoDevices.count > 0 {
            count += 1
        }

        if otrFingerprints.count > 0 {
            count += 1
        }

        return count
    }

    /**
     Show two sections, one for OMEMO and one for OTR.
    */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 && omemoDevices.count > 0 ? omemoDevices.count : otrFingerprints.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableCell(withIdentifier: "FingerprintHeader") as! ZomFingerprintVerificationHeader

        header.label.text = section == 0 && omemoDevices.count > 0 ? "OMEMO" : "OTR"

        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FingerprintCell", for: indexPath)
            as! ZomFingerprintVerificationCell

        cell.delegate = self

        if indexPath.section == 0 && omemoDevices.count > 0 {
            cell.set(omemoDevices[indexPath.row])
        }
        else {
            cell.set(otrFingerprints[indexPath.row])
        }

        return cell
    }

    // MARK: Private methods

    /**
     Calculcate the number of `.untrustedNew` `OMEMODevice`s and `OTRFingerprint`s and show that
     information in the `subtitleLb` label.
    */
    private func updateUntrustedNewFingerprintsInfo() {
        let keys = countKeys()

        ZomFingerprintBaseViewController.setBadge(badgeLb, ok: keys.trusted > 0 && keys.untrustedNew < 1)

        if keys.trusted > 0 || keys.untrustedNew > 0 {
            subtitleLb.text = NSLocalizedString("\(keys.untrustedNew) Untrusted New Codes for \(buddyName())",
                comment: "Subtitle for code verification detail scene")

            descriptionLb.isHidden = false
        }
        else {
            subtitleLb.text = NSLocalizedString("No Zom Codes for \(buddyName())",
                comment: "Subtitle for code verification detail scene")

            descriptionLb.isHidden = true
        }
    }
}
