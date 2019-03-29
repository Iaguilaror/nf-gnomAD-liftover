## Read libraries
library("scales")
library("dplyr")
library("ggplot2")

## Read arguments from command line
args <- commandArgs(trailingOnly = TRUE)

## For debugging
# # arg 1 is $prereq
# args[1] <- "test/results/sample_chr21.unfiltered.liftover.edited.variants_summary.tsv"
# # arg 2 is $target
# args[2] <- "test/data/sample_chr21.unfiltered.liftover.edited_report.pdf"

## Read data
data.df <- read.table(file = args[1], header = T, sep = "\t", stringsAsFactors = T)

## Reorder factor
data.df$variants <- factor(data.df$variants, levels = c("unmapped_variants", "mapped_variants_PASS", "mapped_variants_noPASS","total_variants","mapped_variants"))

### test factor
##factor(data.df$variants)

## extract total variants value
total_variants = data.df[data.df$variants=="total_variants","number"]
## Calculate percentage of variants
data.df$percentage <- data.df$number / total_variants *100

## Keep only informative rows for pie chart
pie.df <- data.df %>% filter(variants == "unmapped_variants" | variants == "mapped_variants_PASS" | variants == "mapped_variants_noPASS") %>% droplevels()

## caculate values for plotting
pie.df$ymax = cumsum(pie.df$percentage)
pie.df$ymin = c(0, head(pie.df$ymax, n = -1))

#Create a custom color scale
myColors <- c("#F8766D","#7CAE00","gray70")
names(myColors) <- levels(pie.df$variants)
colScale <- scale_colour_manual(name = "variants",values = myColors)

## plot donut chart

# get chromosome or sample name from inputfile path
chrname <- unlist(strsplit(basename(args[1]), split = "\\."))[1]

## Donut plot
library(ggrepel)
donut.p <- ggplot(pie.df, aes(fill = variants, ymax = ymax, ymin = ymin, xmax = 100, xmin = 80)) +
  geom_rect(colour = "black") +
  coord_polar(theta = "y") + 
  xlim(c(0, 140)) +
  geom_label_repel(data = pie.df[pie.df$number >0,], aes(fill = variants, 
                                      label = paste(round(percentage,2),"%","(",prettyNum(number, big.mark = ","),")"),
                       x = 130, y = (ymin + ymax)/2),
                   inherit.aes = F, show.legend = F, 
                   size = 2,
                   label.padding = unit(0.2, "lines"))+
  scale_fill_manual(name = "gnomeAD liftover results", values = myColors) +
    # ggtitle( "gnomAD variants remaped to new genome version") +
    labs( caption = paste("Total variants:", total_variants, " \n", date())) +
  theme_minimal() +
  theme(
        panel.grid = element_blank(),
        axis.text = element_blank(),
        axis.title = element_blank(),
        axis.ticks = element_blank(),
        text = element_text(size=5),
        legend.spacing.x = unit(0.1, 'cm'),
        legend.text = element_text( size = 5, face = "bold"),
        legend.title = element_text( size = 6, face = "bold"),
        legend.key.height = unit(0.2, 'cm')
        ) +
  annotate("text", x = 0, y = 0, size = 5, label = chrname)

ggsave(filename = args[2], plot = donut.p, device = "pdf", width = 10.8, height = 7.2 , units = "cm", dpi = 300)