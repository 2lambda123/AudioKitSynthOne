//
//  TuningsPanel+UITableViewDelegate.swift
//  AudioKitSynthOne
//
//  Created by Marcus Hobbs on 6/3/18.
//  Copyright © 2018 AudioKit. All rights reserved.
//

// MARK: - TableViewDelegate

extension TuningsPanelController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if cell.isSelected {
            cell.contentView.backgroundColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == tuningTableView {
            tuningIndex = (indexPath as NSIndexPath).row
            tuningModel.selectTuning(atRow: tuningIndex)
            if let selectedCell = tableView.cellForRow(at: indexPath) {
                selectedCell.contentView.backgroundColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
            }
            tuningDidChange()
        } else if tableView == tuningBankTableView {
            
        } else {
            AKLog("error: no such tableview")
        }
    }
}
