# my_grocery

This is a simple grocery list application, it works as the traditionnal old fashioned pen and paper grocery list.
When you add a product to cart, you cross out this product on paper, this application works that way !

## Getting Started
user manual

# Main page : create grocery shopping list and push to cart 
Products can be added to grocery list easily with text controller field and keyboard suggestion.
If products exists in database, a specific icon will be displayed as product image otherwise a default icon is shown.

The buttons in the footer part, permit to save a list locally: "sauvegarder", load it "restaurer" and delete full list "supprimer".
Deleting list is immediate if not already loaded on screen. 

List is reordonable with drag and drop and swipe move deletes an item in list.
A checkbox checked adds product to cart in second page and product disappears from initial list.

# Second page : added to cart
The second page is very simple and only show products added to cart. A delete icon at the top right permits to clean the page for another list to come.
Second page is called by tapping on the cart icon in top appBar menu and a back arrow permits to return on main screen.

# Third page: create/edit/search product in Firebase collection
Third page is called with the "+" in the main appbar menu and the same back arrow returns user to main screen.
This last page is useful for the user to create/update products list in database and search if a product already exists before creating it !

A modal is called by tappind on the big "+" icon at the bottom right.
A fade in picture prevents null value issues when no image is selected when starting app.

Two options are possible to select a picture for a product : searching a saved picture in phone files or taking a snapshot with camera.
Snapshots are not saved to phone so no need to delete them after creating or edting an item !

Beware there is a small delay between choosing a picture and seeing it on screen, you just need to tap on text field or image field to refresh image.
Of course each product can be deleted in database by tapping on delete icon.

# Conclusion
I have tested my app on my own phone and I have added some minor changes like trimming final empty space in search value when tapping on keyboard suggestion.
A free icon is displayed on screen when installing app on phone instead of default uggly firebase icon :)

